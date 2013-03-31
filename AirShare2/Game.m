#import <GameKit/GameKit.h>

#import "Game.h"
#import "AFNetworking.h"
#import "MusicUpload.h"

#import "Packet.h"
#import "PacketSignIn.h"
#import "PacketGameState.h"
#import "PacketOtherClientQuit.h"
#import "PacketMusic.h"
#import "PacketMusicResponse.h"
#import "PacketPlayMusicNow.h"
#import "PacketVote.h"

const double DELAY_TIME = 2.00000; // wait DELAY_TIME seconds until songs play
const int WAIT_TIME_UPLOAD = 20; // wait time for others to download music after uploading
const int WAIT_TIME_DOWNLOAD = 8; // wait time for others to download music after downloading

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
    
    Packet *packet = [PacketSignIn packetWithPlayerName:_localPlayerName];
	[self sendPacketToServer:packet];
}

- (void)startServerGameWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients
{
	self.isServer = YES;
    
	_session = session;
	_session.available = YES;
	_session.delegate = self;
    _serverPeerID = session.peerID;
    
    self.maxClients = 4;
    
	[_session setDataReceiveHandler:self withContext:nil];
    
    _serverState = ServerStateAcceptingConnections;
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
	//NSLog(@"Game: receive data from peer: %@, data: %@, length: %d", peerID, data, [data length]);
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
            self.players = ((PacketGameState *)packet).players;
            NSMutableArray *removedObjects = [[NSMutableArray alloc] initWithCapacity:5];
            for(PlaylistItem *playlistItem in ((PacketGameState *)packet).playlist) {
                PlaylistItem *inMyPlaylist = [self playlistItemWithID:playlistItem.ID];
                if(inMyPlaylist) {
                    // update the item in my playlist
                    [inMyPlaylist setUpvoteCount:[playlistItem getUpvoteCount]
                                andDownvoteCount:[playlistItem getDownvoteCount]];
                } else {
                    [self.playlist addObject:playlistItem];
                }
            }
            [_playlist removeObjectsInArray:removedObjects];
            
            PlaylistItem *currentItem = ((PacketGameState *)packet).currentPlaylistItem;
            [self.delegate game:self setCurrentItem:currentItem];
            [self.delegate reloadTable];
            
            break;
        }
        case PacketTypeMusic:
        {
            MusicItem *packetMusicItem = ((PacketMusic *)packet).musicItem;
            NSString *ID = packetMusicItem.ID;
            
            MusicItem *musicItem = (MusicItem *)[self playlistItemWithID:ID];
            NSLog(@"Client recieved music packet with description = %@", [packetMusicItem description]);
            if(!musicItem) {
                NSLog(@"Music item not in list!");
                musicItem = packetMusicItem;
            }
            
            //[self addItemToPlaylist:musicItem];
            NSTimer *loadProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                                          target:self
                                                                        selector:@selector(handleLoadProgressTimer:)
                                                                        userInfo:musicItem
                                                                         repeats:YES];
            
            [_downloader downloadFileWithMusicItem:musicItem andSessionID:_serverPeerID completion:^ {
                NSLog(@"Added music item with description: %@", [musicItem description]);
                [self.delegate reloadTable];
                [loadProgressTimer invalidate];
                
                [self hasDownloadedMusic:musicItem myMusic:NO];
            }];
            break;
        }
        case PacketTypePlayMusicNow:
        {
            // instruction to play music
            NSString *ID = ((PacketPlayMusicNow *)packet).ID;
            NSDate *playDate = ((PacketPlayMusicNow *)packet).time;
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:DATE_FORMAT];
            NSString *playDateString = [dateFormatter stringFromDate:playDate];
            
            NSLog(@"Client received packet PlayTypeMusicNow, ID = %@, playString = %@", ID, playDateString);
            
            [self getServerTimeWithCompletion:^(NSDate *serverTime) {
                double delay = [playDate timeIntervalSinceDate:serverTime];
                NSLog(@"Client to play music item, id = %@, delay: %f", ID, delay);
                [self performSelector:@selector(playMusicItemWithSongID:) withObject:ID afterDelay:delay];
            }];
            PlaylistItem *playlistItem = [self playlistItemWithID:ID];
            [_playlist removeObject:playlistItem];
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
        {
			NSLog(@"Client received unexpected packet: %@", packet);
			break;
        }
	}
}

- (void)serverReceivedPacket:(Packet *)packet fromPlayer:(Player *)player
{
	switch (packet.packetType)
	{
		case PacketTypeSignIn:
        {
            player.name = ((PacketSignIn *)packet).playerName;
            
            NSLog(@"Server received sign in from client '%@'", player.name);
            
            [self sendGameStatePacket];
                     
            // TODO: send PacketTypeMusic to client for all songs
            for(PlaylistItem *playlistItem in self.playlist) {
                NSLog(@"Updating player = %@ with item = %@", player.name, [playlistItem description]);
                // only update if you have fully loaded the song
                if(playlistItem.playlistItemType == PlaylistItemTypeSong && playlistItem.loadProgress == 1.0) {
                    PacketMusic *packet = [PacketMusic packetWithMusicItem:(MusicItem *)playlistItem];
                    [self sendPacket:packet toClientWithPeerID:player.peerID];
                }
            }
			break;
        }
        case PacketTypeMusic:
        {
            // instruction to download music
            MusicItem *musicItem  = ((PacketMusic *)packet).musicItem;
            NSLog(@"Server recieved music packet with description: %@", [musicItem description]);
            
            [self addItemToPlaylist:musicItem];
            // since they sent the packet, they must have the song
            [player.hasMusicList setObject:@YES forKey:musicItem.ID];
            
            NSTimer *loadProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                                          target:self
                                                                        selector:@selector(handleLoadProgressTimer:)
                                                                        userInfo:musicItem
                                                                         repeats:YES];
            
            [_downloader downloadFileWithMusicItem:musicItem andSessionID:_serverPeerID completion:^{
                NSLog(@"Added music item with description: %@", [musicItem description]);
                
                [self.delegate reloadTable];
                [loadProgressTimer invalidate];
                
                [self hasDownloadedMusic:musicItem myMusic:NO];
            }];
            break;
        }
        case PacketTypeMusicResponse:
        {
            // means a client has downloaded music
            NSString *ID  = ((PacketMusicResponse *)packet).ID;
            NSLog(@"Server recieved music response packet from player = %@ and ID = %@", player.name, ID);
            
            [player.hasMusicList setObject:@YES forKey:ID];
            MusicItem *musicItem = (MusicItem *)[self playlistItemWithID:ID];
            [self serverTryPlayingMusic:musicItem waitTime:WAIT_TIME_DOWNLOAD];
            
            break;
        }
        case PacketTypeVote:
        {
            // client has voted
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
        {
			[self clientDidDisconnect:player.peerID];
			break;
        }
		default:
        {
			NSLog(@"Server received unexpected packet: %@", packet);
			break;
        }
    }
}

- (void)uploadMusicWithMediaItem:(MPMediaItem *)song
{
    NSLog(@"Game: playMusicWithName: %@", [song valueForProperty:MPMediaItemPropertyTitle]);
    NSString *songName = [song valueForProperty:MPMediaItemPropertyTitle];
    NSString *artistName = [song valueForProperty:MPMediaItemPropertyArtist];
    NSString *ID = [self genRandStringLength:6];
    
    // -1 is placeholder for filesize
    MusicItem *musicItem = [MusicItem musicItemWithName:songName andSubtitle:artistName andID:ID andDate:[NSDate date]];
    
    // temporarily add for display purposes
    [self addItemToPlaylist:musicItem];
    
    NSTimer *loadProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                                  target:self
                                                                selector:@selector(handleLoadProgressTimer:)
                                                                userInfo:musicItem
                                                                 repeats:YES];
    
    NSURL *assetURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
    [_uploader convertAndUpload:musicItem withAssetURL:assetURL andSessionID:_serverPeerID completion:^ {
        // reload one last time to make sure the progress bar is gone
        [self.delegate reloadTable];
        [loadProgressTimer invalidate];
        
        [self hasDownloadedMusic:musicItem myMusic:YES];
        
        NSLog(@"Sending packet with: %@", [musicItem description]);
        PacketMusic *packet = [PacketMusic packetWithMusicItem:musicItem];
        [self sendPacketToAllClients:packet];
    }];
}


- (void)hasDownloadedMusic:(MusicItem *)musicItem myMusic:(BOOL)myMusic
{
    // this can be called both after someone downloads others' music,
    // and after they have uploaded their own music
    
    if(self.isServer) {
        //[self addItemToPlaylist:musicItem];
        // mark that you have item
        [((Player *)[_players objectForKey:_session.peerID]).hasMusicList setObject:@YES forKey:musicItem.ID];
        if(myMusic) {
            [self serverTryPlayingMusic:musicItem waitTime:WAIT_TIME_UPLOAD];
        } else {
            [self serverTryPlayingMusic:musicItem waitTime:WAIT_TIME_DOWNLOAD];
        }
    }
    else {
        // alert the server that you have musicItem
        PacketMusicResponse *packet = [PacketMusicResponse packetWithSongID:musicItem.ID];
        [self sendPacketToServer:packet];
    }
}

- (void)addItemToPlaylist:(PlaylistItem *)playlistItem {
    //NSAssert(self.isServer, @"Client in addItemToPlaylist:");
    
    [_playlist addObject:playlistItem];
    [self.delegate reloadTable];
    if(self.isServer)
        [self sendGameStatePacket];
}


- (void)serverTryPlayingMusic:(MusicItem *)musicItem waitTime:(int)waitTime {
    NSAssert(self.isServer, @"Client in serverTryPlayingMusic:");
    
    if( !_audioPlaying && [self allPlayersHaveMusic:musicItem]) {
        _audioPlaying = YES;
        [_waitTimer invalidate];
        [self playItem:musicItem];
    } else if(!_audioPlaying) {
        NSLog(@"created wait timer");
        // create a timer to start playing unless you receive another PacketMusicResponse
        _waitTimer = [NSTimer scheduledTimerWithTimeInterval:waitTime
                                                      target:self
                                                    selector:@selector(handleWaitTimer:)
                                                    userInfo:musicItem
                                                     repeats:NO];
    }
}

- (BOOL)allPlayersHaveMusic:(MusicItem *)musicItem
{
    for (NSString *peerID in _players)
	{
		Player *player = [self playerWithPeerID:peerID];
		if (![player.hasMusicList objectForKey:musicItem.ID]) {
            //NSLog(@"Player %@ does not have music %@", player.name, musicItem.name);
			return NO;
        }
	}
    return YES;
}

- (void)playItem:(PlaylistItem *)playlistItem
{
    NSAssert(self.isServer, @"Client in playItem:");
    [_waitTimer invalidate];
    _waitTimer = nil;
    
    if(playlistItem.playlistItemType == PlaylistItemTypeSong) {
        [self serverStartPlayingMusic:(MusicItem *)playlistItem];
    }
}

- (void)serverStartPlayingMusic:(MusicItem *)musicItem {
    NSAssert(self.isServer, @"Client in serverStartPlayingMusic:");
    
    _audioPlaying = YES;
    
    [self getServerTimeWithCompletion:^(NSDate *serverTime) {
        [self performSelector:@selector(playMusicItemWithSongID:) withObject:musicItem.ID afterDelay:DELAY_TIME];
        
        NSDate *playDate = [serverTime dateByAddingTimeInterval:DELAY_TIME];
        NSLog(@"Playdate = %@", playDate);
        PacketPlayMusicNow *packet = [PacketPlayMusicNow packetWithSongID:musicItem.ID andTime:playDate];
        [self sendPacketToAllClients:packet];
        
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
        
        NSLog(@"Server preparing to play music item with name = %@ and delay = %f", musicItem.name, DELAY_TIME);
    }];

}

- (void)playMusicItemWithSongID:(NSString *)ID
{
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@.m4a", ID];
    NSString *songPath = [documentsDirectoryPath stringByAppendingPathComponent:fileName];
    NSURL *songURL = [[NSURL alloc] initWithString:songPath];
    
    NSLog(@"Playing music item, songPath = %@", songPath);
    NSError *error;
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:songURL error:&error];
    _audioPlayer.delegate = self;
    if (_audioPlayer == nil) {
        _audioPlaying = NO;
        NSLog(@"AudioPlayer did not load properly: %@", [error description]);
    } else {
        _audioPlaying = YES;
        [_audioPlayer prepareToPlay];
        [_audioPlayer play];
        _audioPlayerTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                             target:self
                                                           selector:@selector(updatePlaybackProgress:)
                                                           userInfo:nil
                                                            repeats:YES];
    }
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"AudioPlayer finished playing, success? %@", flag ? @"YES" : @"NO");
    [self.delegate setPlaybackProgress:0.0];
    [self.delegate audioPlayerFinishedPlaying];
    [_audioPlayerTimer invalidate];
    _audioPlayerTimer = nil;
    _audioPlaying = NO;
    
    if(self.isServer) {
        // try to play the next item on the list that is not loading
        for(PlaylistItem *playlistItem in _playlist) {
            if(playlistItem.loadProgress == 1.0) {
                [self serverTryPlayingMusic:(MusicItem *)playlistItem waitTime:WAIT_TIME_UPLOAD];
                break;
            }
        }
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

- (void)sendPacket:(Packet *)packet toClientWithPeerID:(NSString *)peerID
{
    //NSLog(@"Sending packet to server");
	GKSendDataMode dataMode = GKSendDataReliable;
	NSData *data = [packet data];
	NSError *error;
	if (![_session sendData:data toPeers:[NSArray arrayWithObject:peerID] withDataMode:dataMode error:&error])
	{
		NSLog(@"Error sending data to client: %@", error);
	}
}
- (void)sendPacketToServer:(Packet *)packet
{
    //NSLog(@"Sending packet to server");
	GKSendDataMode dataMode = GKSendDataReliable;
	NSData *data = [packet data];
	NSError *error;
	if (![_session sendData:data toPeers:[NSArray arrayWithObject:_serverPeerID] withDataMode:dataMode error:&error])
	{
		NSLog(@"Error sending data to server: %@", error);
	}
}

- (void)sendGameStatePacket {
    NSAssert(self.isServer, @"Client in sendGameStatePacket:");
    
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

- (void)removeCancelledUpload:(NSInteger)index
{
    if ([[_playlist objectAtIndex:index] isCancelled]) {
        [_playlist removeObjectAtIndex:index];
    }
}

#pragma mark - Utility

- (NSString *)displayNameForPeerID:(NSString *)peerID
{
	return [_session displayNameForPeer:peerID];
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
    return nil;
}
- (NSString *)genRandStringLength:(int)len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i = 0; i < len; i++) {
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

#pragma mark - Time Utilities

- (void)getServerTimeWithCompletion:(void(^)(NSDate *serverTime))completionBlock
{
    NSError *error;
    NSDate *downloadStartTime = [NSDate date];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@airshare-time.php", BASE_URL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSData *receivedData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:nil
                                                             error:&error];
    double downloadTime = [downloadStartTime timeIntervalSinceNow] * -1000.0;
    downloadTime /= 1000.0;
    NSString *dateString = [[NSString alloc] initWithData:receivedData
                                                 encoding:NSUTF8StringEncoding];
    //NSLog(@"Time from server = %@", dateString);
    if(error) {
        NSLog(@"Error: %@", error);
        completionBlock([NSDate date]);
    } else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:DATE_FORMAT];
        NSDate *time = [dateFormatter dateFromString:dateString];
        NSLog(@"Download time = %f", downloadTime);
        time = [time dateByAddingTimeInterval:downloadTime];
        completionBlock(time);
    }
}

- (void)updatePlaybackProgress:(NSTimer *)timer {
    float total = _audioPlayer.duration;
    float fraction = _audioPlayer.currentTime / total;
    
    [self.delegate setPlaybackProgress:fraction];
}

- (void)handleWaitTimer:(NSTimer *)timer {
    NSLog(@"Wait timer called! Playing music");
    _audioPlaying = YES;
    // means you should start playing MusicItem
    MusicItem *musicItem = (MusicItem *)[timer userInfo];
    [self serverStartPlayingMusic:musicItem];
}
- (void)handleLoadProgressTimer:(NSTimer *)timer {
    // reload only the updated item
   // PlaylistItem *playlistItem = (PlaylistItem *)[timer userInfo];
    [self.delegate reloadTable];
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

# pragma mark - End Session Handling

- (void)destroyFilesWithSessionID:(NSString *)sessionID
{
    NSError *error;
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@airshare-destroy.php?sessionid=%@", BASE_URL, sessionID]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [NSURLConnection sendSynchronousRequest:request
                          returningResponse:nil
                                      error:&error];
    if(error) {
        NSLog(@"Error destroying files: %@", error);
    } else {
        NSLog(@"Files with sessionid = %@ destroyed", sessionID);
    }
}

- (void)endSession
{
	_serverState = ServerStateIdle;
	_session.available = NO;
	_session.delegate = nil;
	_session = nil;
    _players = nil;
    _playlist = nil;
    
    [_audioPlayer stop];
	[_session disconnectFromAllPeers];
    
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
		if (self.isServer) {
            [self destroyFilesWithSessionID:_session.sessionID];
			Packet *packet = [Packet packetWithType:PacketTypeServerQuit];
			[self sendPacketToAllClients:packet];
		} else {
			Packet *packet = [Packet packetWithType:PacketTypeClientQuit];
			[self sendPacketToServer:packet];
		}
	}
    
	[_session disconnectFromAllPeers];
	_session.delegate = nil;
	_session = nil;
    [_audioPlayer stop];
    _audioPlayer = nil;
    
	[self.delegate game:self didQuitWithReason:reason];
}
@end