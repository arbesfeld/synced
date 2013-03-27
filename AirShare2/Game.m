#import <GameKit/GameKit.h>

#import "Game.h"
#import "AFNetworking.h"
#import "MusicUpload.h"

#import "Packet.h"
#import "PacketSignInResponse.h"
#import "PacketGameState.h"
#import "PacketOtherClientQuit.h"
#import "PacketMusic.h"
#import "PacketMusicResponse.h"
#import "PacketPlayMusicNow.h"
#import "PacketVote.h"

const double DELAY_TIME = 2.000; // wait DELAY_TIME seconds until songs play


@implementation Game
{
	NSString *_serverPeerID;
	NSString *_localPlayerName;
    
    NSDateFormatter *_dateFormatter;
    
    ServerState _serverState;
}

@synthesize delegate = _delegate;
@synthesize isServer = _isServer;
@synthesize session = _session;
@synthesize players = _players;
@synthesize playlist = _playlist;

- (void)dealloc
{
    #ifdef DEBUG
	NSLog(@"dealloc %@", self);
    #endif
}

- (id)init
{
	if ((self = [super init]))
	{
		_players = [NSMutableDictionary dictionaryWithCapacity:4];
        _playlist = [[NSMutableArray alloc] initWithCapacity:10];
        _uploader = [[MusicUpload alloc] init];
        _downloader = [[MusicDownload alloc] init];
        _audioPlayer =  nil;
        _audioPlaying = NO;
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:DATE_FORMAT];
	}
	return self;
}

#pragma mark - Game Logic

- (void)startClientGameWithSession:(GKSession *)session playerName:(NSString *)name server:(NSString *)peerID
{
	self.isServer = NO;
    
	_session = session;
	_session.available = NO;
	_session.delegate = self;
    
    self.maxClients = 4;
    
	[_session setDataReceiveHandler:self withContext:nil];
    
	_serverPeerID = peerID;
	_localPlayerName = name;
    NSLog(@"Name: %@", _localPlayerName);
    
	[self.delegate gameWaitingForServerReady:self];
    
    Packet *packet = [PacketSignInResponse packetWithPlayerName:_localPlayerName];
	[self sendPacketToServer:packet];
}

- (void)startServerGameWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients
{
    NSLog(@"startServerGameWithSession:");
	self.isServer = YES;
    
	_session = session;
	_session.available = YES;
	_session.delegate = self;
    
    self.maxClients = 4;
    
	[_session setDataReceiveHandler:self withContext:nil];
    
    _serverState = ServerStateAcceptingConnections;
    
	[self.delegate gameWaitingForClientsReady:self];
    NSLog(@"Session displayname: %@", _session.displayName);
    _localPlayerName = name;
    
	Player *player = [[Player alloc] init];
	player.name = _localPlayerName;
	player.peerID = _session.peerID;
    
	[_players setObject:player forKey:player.peerID];
}

#pragma mark - GKSession Data Receive Handler

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peerID inSession:(GKSession *)session context:(void *)context
{
    #ifdef DEBUG
	NSLog(@"Game: receive data from peer: %@, data: %@, length: %d", peerID, data, [data length]);
    #endif
    
	Packet *packet = [Packet packetWithData:data];
	if (packet == nil)
	{
		NSLog(@"Invalid packet: %@", data);
		return;
	}
    
	Player *player = [self playerWithPeerID:peerID];
    
	if (self.isServer)
		[self serverReceivedPacket:packet fromPlayer:player];
	else
		[self clientReceivedPacket:packet];
}

- (void)clientReceivedPacket:(Packet *)packet
{
	switch (packet.packetType)
	{
        case PacketTypeGameState:
        {
            NSLog(@"Client received game state packet");
            [self.players removeAllObjects];
            [self.playlist removeAllObjects];
            self.players = ((PacketGameState *)packet).players;
            self.playlist = ((PacketGameState *)packet).playlist;
            PlaylistItem *currentItem = ((PacketGameState *)packet).currentPlaylistItem;
            [self.delegate game:self setCurrentItem:currentItem];
            [self.delegate reloadTable];
            
            break;
        }
        case PacketTypeMusic:
        {
            // instruction to download music
            NSString *songName  = ((PacketMusic *)packet).songName;
            NSString *artistName  = ((PacketMusic *)packet).artistName;
            NSString *ID  = ((PacketMusic *)packet).ID;
            NSLog(@"Client recieved music packet with songName %@ and artistName %@", songName, artistName);
             
            [_downloader downloadFileWithName:songName completion:^ {
                MusicItem *musicItem = [MusicItem musicItemWithName:songName andSubtitle:artistName andID:ID];
                NSLog(@"Added music item with description: %@", [musicItem description]);

                [self hasDownloadedMusic:musicItem];
            }];
            break;
        }
        case PacketTypePlayMusicNow:
        {
            NSString *songName = ((PacketPlayMusicNow *)packet).songName;
            NSDate *playDate = ((PacketPlayMusicNow *)packet).time;
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:DATE_FORMAT];
            NSString *playDateString = [dateFormatter stringFromDate:playDate];
            
            NSLog(@"Client received packet PlayTypeMusicNow, song name = %@, playString = %@", songName, playDateString);
            
            AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL]];
            NSString *urlString = [NSString stringWithFormat:@"%@airshare-time.php", BASE_URL];
            NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                                    path:urlString
                                                              parameters:nil];
        
            
            __block NSDate *downloadStart = [NSDate date];//nil;
            
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
            [operation setDownloadProgressBlock:^(NSUInteger bytesDownloaded, long long totalBytesDownloaded, long long totalBytesExpectedToDownload) {
                // initliaze downloadStart when we first get data
                if(downloadStart == nil)
                    downloadStart = [NSDate date];
                
                NSLog(@"Downloaded %lld bytes", totalBytesDownloaded);
            }];
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Success, data length: %d", [responseObject length]);
                
                NSDate *currentDate = [_dateFormatter dateFromString:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]];
                
                // calculate time to download and add to currentDate
                NSDate *downloadFinish = [NSDate date];
                NSTimeInterval downloadTime = [downloadFinish timeIntervalSinceDate:downloadStart];
                NSLog(@"download time: %f", downloadTime);
                [currentDate dateByAddingTimeInterval:downloadTime];
                
                // have to multiply by 1000 then devide to get double precision
                double delay = [playDate timeIntervalSinceDate:currentDate] * 1000.0;
                delay /= 1000.0;
                
                NSLog(@"Client to play music item, song name = %@, delay: %f", songName, delay);
                [self performSelector:@selector(playMusicItemWithSongName:) withObject:songName afterDelay:delay];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error: %@", error);
            }];
            
            [operation start];
            
            break;
        }
        case PacketTypeServerQuit:
        {
			[self quitGameWithReason:QuitReasonServerQuit];
			break;
        }
        case PacketTypeOtherClientQuit:
        {
            PacketOtherClientQuit *quitPacket = ((PacketOtherClientQuit *)packet);
            [self clientDidDisconnect:quitPacket.peerID];
			
			break;
		}
        default:
			NSLog(@"Client received unexpected packet: %@", packet);
			break;
	}
}

- (void)serverReceivedPacket:(Packet *)packet fromPlayer:(Player *)player
{
	switch (packet.packetType)
	{
		case PacketTypeSignInResponse:
        {
            player.name = ((PacketSignInResponse *)packet).playerName;
            
            NSLog(@"Server received sign in from client '%@'", player.name);
            
            [self sendGameStatePacket];
			break;
        }
        case PacketTypeMusic:
        {
            NSString *songName  = ((PacketMusic *)packet).songName;
            NSString *artistName  = ((PacketMusic *)packet).artistName;
            NSString *ID  = ((PacketMusic *)packet).ID;
            NSLog(@"Server recieved music packet with song = %@, artist = %@, ID = %@", songName, artistName, ID);
            
            [player.hasMusicList setObject:@YES forKey:ID];
            
            [_downloader downloadFileWithName:songName completion:^{
                MusicItem *musicItem = [MusicItem musicItemWithName:songName andSubtitle:artistName andID:ID];
                NSLog(@"Added music item with description: %@", [musicItem description]);
                
                [self hasDownloadedMusic:musicItem];
            }];
            break;
        }
        case PacketTypeMusicResponse:
        {
            NSString *ID  = ((PacketMusicResponse *)packet).ID;
            NSLog(@"Server recieved music response packet from player = %@ and ID = %@", player.name, ID);
            
            [player.hasMusicList setObject:@YES forKey:ID];
            
            MusicItem *musicItem = (MusicItem *)[self playlistItemWithID:ID];
            if(!_audioPlaying && [self allPlayersHaveMusic:musicItem]) {
                _audioPlaying = YES;
                [self serverStartPlayingMusic:musicItem];
            }
            break;
        }
        case PacketTypeVote:
        {
            NSString *ID  = ((PacketVote *)packet).ID;
            int amount  = [((PacketVote *)packet) getAmount];
            BOOL upvote  = [((PacketVote *)packet) getUpvote];
            NSLog(@"Server recieved vote from player = %@, ID = %@, amount = %d, upvote = %@", player.name, ID, amount, upvote == YES ? @"YES" : @"NO");
            
            PlaylistItem *playlistItem = [self playlistItemWithID:ID];
            if(upvote) {
                [playlistItem upvote:amount];
            } else {
                [playlistItem downvote:amount];
            }
            [self.delegate reloadTable];
            [self sendGameStatePacket];
            break;
        }
            
        case PacketTypeClientQuit:
			[self clientDidDisconnect:player.peerID];
			break;
            
		default:
			NSLog(@"Server received unexpected packet: %@", packet);
			break;
	}
}

- (void)uploadMusicWithMediaItem:(MPMediaItem *)song
{
    NSLog(@"Game: playMusicWithName: %@", [song valueForProperty:MPMediaItemPropertyTitle]);
    
    [_uploader convertAndUpload:song completion:^ {
        NSString *songName = [song valueForProperty:MPMediaItemPropertyTitle];
        NSString *artistName = [song valueForProperty:MPMediaItemPropertyArtist];
        NSString *ID = [self genRandStringLength:6];
        MusicItem *musicItem = [MusicItem musicItemWithName:songName andSubtitle:artistName andID:ID];
        
        NSLog(@"Sending packet with songName %@ and artistName %@ and ID = %@", songName, artistName, ID);
        [self hasDownloadedMusic:musicItem];
        PacketMusic *packet = [PacketMusic packetWithSongName:songName andArtistName:artistName andID:ID];
        [self sendPacketToAllClients:packet]; }
    ];
}

- (void)addItemToPlaylist:(PlaylistItem *)playlistItem {
    if(!self.isServer)
        return;
    
    [_playlist addObject:playlistItem];
    [self.delegate reloadTable];
    [self sendGameStatePacket];
}

- (void)playItem:(PlaylistItem *)playlistItem
{
    if(!self.isServer)
        return;
    if(playlistItem.playlistItemType == PlaylistItemTypeSong) {
        [self serverStartPlayingMusic:(MusicItem *)playlistItem];
    }
}

- (void)hasDownloadedMusic:(MusicItem *)musicItem
{
    if(!self.isServer) {
        // alert the server that you have musicItem
        PacketMusicResponse *packet = [PacketMusicResponse packetWithSongID:musicItem.ID];
        [self sendPacketToServer:packet];
    }
    else {
        [self addItemToPlaylist:musicItem];
        
        // mark that you have item
        [((Player *)[_players objectForKey:_session.peerID]).hasMusicList setObject:@YES forKey:musicItem.ID];
        
        // see if you should start playing
        if( !_audioPlaying && [self allPlayersHaveMusic:musicItem]) {
            _audioPlaying = YES;
            [self serverStartPlayingMusic:musicItem];
        }
    }
}

- (BOOL)allPlayersHaveMusic:(MusicItem *)musicItem
{
    for (NSString *peerID in _players)
	{
		Player *player = [self playerWithPeerID:peerID];
		if (![player.hasMusicList objectForKey:musicItem.ID]) {
            NSLog(@"Player %@ does not have music %@", player.name, musicItem.name);
			return NO;
        }
	}
    return YES;
}

- (void)serverStartPlayingMusic:(MusicItem *)musicItem {
    if(!self.isServer) {
        NSLog(@"Client is in serverStartPlayingMusic!");
        return;
    }
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL]];
    NSString *urlString = [NSString stringWithFormat:@"%@airshare-time.php", BASE_URL];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET"
                                                            path:urlString
                                                      parameters:nil];
    
    __block NSDate *downloadStart = [NSDate date];//nil;
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    [operation setDownloadProgressBlock:^(NSUInteger bytesDownloaded, long long totalBytesDownloaded, long long totalBytesExpectedToDownload) {
        // initliaze downloadStart when we first get data
        if(downloadStart == nil)
            downloadStart = [NSDate date];
        
        NSLog(@"Downloaded %lld bytes", totalBytesDownloaded);
    }];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSLog(@"Success, data length: %d", [responseObject length]);
        
        
        NSDate *currentDate = [_dateFormatter dateFromString:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]];
        
        // calculate time to download and add to currentDate
        NSDate *downloadFinish = [NSDate date];
        NSTimeInterval downloadTime = [downloadFinish timeIntervalSinceDate:downloadStart];
        NSLog(@"download time: %f", downloadTime);
        [currentDate dateByAddingTimeInterval:downloadTime];
        
        NSDate *playDate = [currentDate dateByAddingTimeInterval:DELAY_TIME];
        [self performSelector:@selector(playMusicItemWithSongName:) withObject:musicItem.name afterDelay:DELAY_TIME];
        
        // now remove the item from the list and make it the "current song"
        [self.delegate game:self setCurrentItem:musicItem];
        
        PlaylistItem *removedItem = nil;
        for(PlaylistItem *playlistItem in _playlist) {
            if([playlistItem isEqual:musicItem]) {
                removedItem = playlistItem;
                break;
            }
        }
        [_playlist removeObject:removedItem];
        
        [self.delegate reloadTable];
        [self sendGameStatePacket];
        
        PacketPlayMusicNow *packet = [PacketPlayMusicNow packetWithSongName:musicItem.name andTime:playDate];
        [self sendPacketToAllClients:packet];
        
        NSLog(@"Server preparing to play music item with name = %@ and delay = %f", musicItem.name, DELAY_TIME);
    }
     
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
    [operation start];
}

- (void)playMusicItemWithSongName:(NSString *)songName 
{
    
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
    songName = [[songName componentsSeparatedByCharactersInSet:
                           [[NSCharacterSet alphanumericCharacterSet] invertedSet]]
                          componentsJoinedByString:@""];
    NSString *fileName = [NSString stringWithFormat:@"%@.m4a", songName];
    NSString *songPath = [documentsDirectoryPath stringByAppendingPathComponent:fileName];
    NSURL *songURL = [[NSURL alloc] initWithString:songPath];
    
    NSLog(@"Playing music item, song = %@", songName);
    NSError *error;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:songURL error:&error];
    _audioPlayer.delegate = self;
    if (_audioPlayer == nil) {
        NSLog(@"AudioPlayer did not load properly: %@", [error description]);
    } else {
        [_audioPlayer prepareToPlay];
        [_audioPlayer play];
    }
    
}

- (void)sendGameStatePacket {
    if(!self.isServer)
        return;
    
    Packet *packet = [PacketGameState packetWithPlayers:_players andPlaylist:_playlist andCurrentItem:[self.delegate getCurrentPlaylistItem]];
    [self sendPacketToAllClients:packet];
}

- (void)sendVotePacketForItem:(PlaylistItem *)selectedItem andAmount:(int)amount upvote:(BOOL)upvote {
    if(self.isServer) {
        // we have handled the upvote, now send a game state packet
        [self sendGameStatePacket];
    } else {
        // let the server know amount the upvote
        PacketVote *packet = [PacketVote packetWithSongID:selectedItem.ID andAmount:amount upvote:upvote];
        [self sendPacketToServer:packet];
    }
}
#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    _audioPlaying = NO;
    NSLog(@"AudioPlayer finished playing");
    if(self.isServer && _playlist.count != 0) {
        // try to play the next item on the list
        NSLog(@"Server is starting song: %@", [[_playlist objectAtIndex:0] description]);
        [self playItem:[_playlist objectAtIndex:0]];
    }
}
#pragma mark - Networking

- (void)sendPacketToAllClients:(Packet *)packet
{
	GKSendDataMode dataMode = GKSendDataReliable;
	NSData *data = [packet data];
	NSError *error;
	if (![_session sendDataToAllPeers:data withDataMode:dataMode error:&error])
	{
		NSLog(@"Error sending data to clients: %@", error);
	}
}

- (void)sendPacketToServer:(Packet *)packet
{
    NSLog(@"Sending packet to server");
	GKSendDataMode dataMode = GKSendDataReliable;
	NSData *data = [packet data];
	NSError *error;
	if (![_session sendData:data toPeers:[NSArray arrayWithObject:_serverPeerID] withDataMode:dataMode error:&error])
	{
		NSLog(@"Error sending data to server: %@", error);
	}
}

#pragma mark - GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    #ifdef DEBUG
	NSLog(@"Game: peer %@ changed state %d", peerID, state);
    #endif
    
    switch (state)
    {
        case GKPeerStateAvailable:
            break;
            
        case GKPeerStateUnavailable:
            break;
            
            // A new client has connected to the server.
        case GKPeerStateConnected:
            if (self.isServer)
            {
                [self clientDidConnect:peerID];
            }
            break;
            
            // A client has disconnected from the server.
        case GKPeerStateDisconnected:
            if (self.isServer)
            {
                [self clientDidDisconnect:peerID];
            }
            else if ([peerID isEqualToString:_serverPeerID])
            {
                [self quitGameWithReason:QuitReasonConnectionDropped];
            }
            break;
            
        case GKPeerStateConnecting:
            break;
    }
    
}


- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    #ifdef DEBUG
	NSLog(@"Game: connection request from peer %@", peerID);
    #endif
    
	if (_isServer && _serverState == ServerStateAcceptingConnections && [_players count] < self.maxClients)
	{
		NSError *error;
		if ([session acceptConnectionFromPeer:peerID error:&error])
			NSLog(@"Game: Connection accepted from peer %@", peerID);
		else
			NSLog(@"Game: Error accepting connection from peer %@, %@", peerID, error);
	}
	else  // not accepting connections or too many clients
	{
		[session denyConnectionFromPeer:peerID];
	}
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
    #ifdef DEBUG
	NSLog(@"Game: connection with peer %@ failed %@", peerID, error);
    #endif
    
	// Not used.
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
#ifdef DEBUG
	NSLog(@"Game: session failed %@", error);
#endif
    
	if ([[error domain] isEqualToString:GKSessionErrorDomain])
	{
        [self quitGameWithReason:QuitReasonConnectionDropped];
	}
}

#pragma mark - Utility

- (NSString *)displayNameForPeerID:(NSString *)peerID
{
	return [_session displayNameForPeer:peerID];
}

- (NSString *)genRandStringLength:(int)len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}

- (void)clientDidConnect:(NSString *)peerID
{
    if([_players objectForKey:peerID] == nil) {
        Player *player = [[Player alloc] init];
        player.peerID = peerID;
        [_players setObject:player forKey:player.peerID];
        [self.delegate gameServer:self clientDidConnect:player];
    }
}

- (void)clientDidDisconnect:(NSString *)peerID
{
    Player *player = [self playerWithPeerID:peerID];
    if (player != nil)
    {
        [_players removeObjectForKey:peerID];
        
        // Tell the other clients that this one is now disconnected.
        if (self.isServer)
        {
            PacketOtherClientQuit *packet = [PacketOtherClientQuit packetWithPeerID:peerID];
            [self sendPacketToAllClients:packet];
        }
        [self.delegate gameServer:self clientDidDisconnect:player];
    }
}


- (Player *)playerWithPeerID:(NSString *)peerID
{
	return [_players objectForKey:peerID];
}

- (PlaylistItem *)playlistItemWithID:(NSString *)ID
{
    for(int i = 0; i < _playlist.count; i++) {
        if([((PlaylistItem *)_playlist[i]).ID isEqualToString:ID]) {
            return _playlist[i];
        }
    }
    NSLog(@"Playlist item %@ not found!", ID);
    return nil;
}

# pragma mark - Time Utilities

- (NSDate *)getTimeFromServer
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@airshare-time.php", BASE_URL]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSError *error;
    NSData *receivedData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:nil
                                                             error:&error];
    
    NSString *dateString = [[NSString alloc] initWithData:receivedData
                                                 encoding:NSUTF8StringEncoding];
    NSLog(@"Time from server = %@", dateString);
    if(error) {
      NSLog(@"Error: %@", error);
        return [NSDate date];
    } else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:DATE_FORMAT];
        NSDate *time = [dateFormatter dateFromString:dateString];
        
        return time;
    }
}

# pragma mark - End Session Handling

- (void)endSession
{
	_serverState = ServerStateIdle;
    
	[_session disconnectFromAllPeers];
	_session.available = NO;
	_session.delegate = nil;
	_session = nil;
    
    _players = nil;
    
	[self.delegate gameServerSessionDidEnd:self];
}

- (void)stopAcceptingConnections
{
	_serverState = ServerStateIgnoringNewConnections;
	_session.available = NO;
}

- (void)quitGameWithReason:(QuitReason)reason
{
	if (reason == QuitReasonUserQuit)
	{
		if (self.isServer)
		{
			Packet *packet = [Packet packetWithType:PacketTypeServerQuit];
			[self sendPacketToAllClients:packet];
		}
		else
		{
			Packet *packet = [Packet packetWithType:PacketTypeClientQuit];
			[self sendPacketToServer:packet];
		}
	}
    
	[_session disconnectFromAllPeers];
	_session.delegate = nil;
	_session = nil;
    
	[self.delegate game:self didQuitWithReason:reason];
}
@end