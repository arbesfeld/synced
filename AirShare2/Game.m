#import <GameKit/GameKit.h>

#import "Game.h"
#import "AFNetworking.h"
#import "MusicUpload.h"

#import "Packet.h"
#import "PacketSignIn.h"
#import "PacketGameState.h"
#import "PacketOtherClientQuit.h"
#import "PacketMusicDownload.h"
#import "PacketMusicResponse.h"
#import "PacketPlayMusicNow.h"
#import "PacketVote.h"
#import "PacketPlaylistItem.h"
#import "PacketSyncResponse.h"
#import "PacketCancelMusic.h"

const double DELAY_TIME = 2.00000; // wait DELAY_TIME seconds until songs play
const int WAIT_TIME_UPLOAD = 25; // server wait time for others to download music after uploading
const int WAIT_TIME_DOWNLOAD = 20; // server wait time for others to download music after downloading
const int SYNC_PACKET_COUNT = 100;
const int PLAY_ITERATIONS = 5; // how many times we test our players to find playStartTime
const double BACKGROUND_TIME = -0.2; // the additional time it takes when app is in background
const double MOVIE_TIME = -0.1; // the additional time it takes for movies

typedef enum
{
    GameStateIdle,
    GameStatePreparingToPlayMedia,
    GameStatePlayingMusic,
    GameStatePlayingMovie,
    GameStateQuitting,
} GameState;

@implementation Game
{
	NSString *_serverPeerID;
	NSString *_localPlayerName;
    
    NSDateFormatter *_dateFormatter;
    
    ServerState _serverState;
    GameState _gameState;
    
    MusicUpload *_uploader;
    MusicDownload *_downloader;
    
    NSTimer *_audioPlayerTimer, *_waitTimer, *_playMusicTimer;
    BOOL _haveSkippedThisItem;
    int _skipItemCount, _syncPacketCount;
}

@synthesize delegate = _delegate;
@synthesize isServer = _isServer;
@synthesize session = _session;
@synthesize players = _players;
@synthesize playlist = _playlist;

- (void)dealloc
{
	NSLog(@"dealloc %@", self);
}

#pragma mark - Game Logic
- (void)startGame
{
    _players = [NSMutableDictionary dictionaryWithCapacity:4];
    _playlist = [[NSMutableArray alloc] initWithCapacity:10];
    
    _uploader = [[MusicUpload alloc] init];
    _downloader = [[MusicDownload alloc] init];
    _audioPlayer =  nil;
    _dateFormatter = [[NSDateFormatter alloc] init];
    _haveSkippedThisItem = NO;
    [_dateFormatter setDateFormat:DATE_FORMAT];
    
    _gameState = GameStateIdle;
    
    self.maxClients = 4;
}

- (void)startClientGameWithSession:(GKSession *)session playerName:(NSString *)name server:(NSString *)peerID
{
    [self startGame];
    
	self.isServer = NO;
    
	_session = session;
	_session.available = NO;
	_session.delegate = self;
    
    
	[_session setDataReceiveHandler:self withContext:nil];
    
	_serverPeerID = peerID;
	_localPlayerName = name;
    
    Packet *packet = [PacketSignIn packetWithPlayerName:_localPlayerName];
	[self sendPacketToServer:packet];
    
    [self.delegate game:self setSkipItemCount:0];
}

- (void)startServerGameWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients
{
    [self startGame];
    
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
    [self.delegate game:self setSkipItemCount:0];
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
            
            _skipItemCount = ((PacketGameState *)packet).skipCount;
            [self.delegate game:self setSkipItemCount:_skipItemCount];
            
            [self.delegate reloadTable];
            
            break;
        }
        case PacketTypeSync:
        {
            // respond with your time
            PacketSyncResponse *packetResponse = [PacketSyncResponse packetWithTime:[NSDate date]];
            packetResponse.packetNumber = packet.packetNumber;
        
            [self sendPacketToServer:packetResponse];
            
            break;
        }
        case PacketTypePlaylistItem:
        {
            PlaylistItem *playlistItem = ((PacketPlaylistItem *)packet).playlistItem;
            NSLog(@"Client received playlistItemPacket with song %@", playlistItem.name);
            [self addItemToPlaylist:playlistItem];
            break;
        }
        case PacketTypeMusicDownload:
        {
            NSString *ID = ((PacketMusicDownload *)packet).ID;
            [self downloadMusicWithID:ID];
            break;
        }
        case PacketTypePlayMusicNow:
        {
            // instruction to play music
            NSString *ID = ((PacketPlayMusicNow *)packet).ID;
            NSDate *time = ((PacketPlayMusicNow *)packet).time;
            
            MediaItem *mediaItem = (MediaItem *)[self playlistItemWithID:ID];
            
            _gameState = GameStatePreparingToPlayMedia;
            [self playMediaItem:mediaItem withStartTime:time];
            
            break;
        }
        case PacketTypeVote:
        {
            // client has voted
            NSString *ID  = ((PacketVote *)packet).ID;
            int amount  = [((PacketVote *)packet) getAmount];
            BOOL upvote  = [((PacketVote *)packet) getUpvote];
            NSLog(@"Client recieved vote, ID = %@, amount = %d, upvote = %@", ID, amount, upvote == YES ? @"YES" : @"NO");
            
            PlaylistItem *playlistItem = [self playlistItemWithID:ID];
            if(upvote) {
                [playlistItem upvote:amount];
            } else {
                [playlistItem downvote:amount];
            }
            playlistItem.justVoted = YES;
            [self.delegate reloadTable];
            
            break;
        }
        case PacketTypeSkipMusic:
        {
            NSLog(@"Client received PacketTypeSkipMusic");
            _skipItemCount++;
            [self.delegate game:self setSkipItemCount:_skipItemCount];
            [self trySkippingSong];
            break;
        }
        case PacketTypeCancelMusic:
        {
            NSLog(@"Client received PacketTypeCancelMusic");
            // cancel the song
            NSString *ID = ((PacketCancelMusic *)packet).ID;
            PlaylistItem *playlistItem = [self playlistItemWithID:ID];
            
            [self cancelMusic:playlistItem];
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
            
            [self startupRoutineForPlayer:player];
            NSLog(@"Server received sign in from client '%@'", player.name);
            //NSLog(@"Players = %@", [_players description]);
			break;
        }
        case PacketTypeSyncResponse:
        {
            NSDate *receiveTime = [NSDate date];
            //NSLog(@"PacketTypeSyncResponse with packetNumer = %d", packet.packetNumber);
            NSDate *sendTime = player.packetSendTime[packet.packetNumber];
            NSTimeInterval packetSendTime = [receiveTime timeIntervalSinceDate:sendTime] / 2.0;
            //NSLog(@"Packet send time = %f", packetSendTime);
            
            NSDate *theirTime = ((PacketSyncResponse *)packet).time;
            theirTime = [theirTime dateByAddingTimeInterval:packetSendTime];
            
            NSTimeInterval timeOffset = [theirTime timeIntervalSinceDate:receiveTime];
            
            player.timeOffset += timeOffset;
            player.syncPacketsReceived++;
            
            NSLog(@"Received sync response with timeOffset = %f", timeOffset);
            
            if(packet.packetNumber < SYNC_PACKET_COUNT - 1) {
                Packet *sendPacket = [Packet packetWithType:PacketTypeSync];
                sendPacket.packetNumber = packet.packetNumber + 1;
                
                //mark when you sent this packet
                player.packetSendTime[sendPacket.packetNumber] = [NSDate date];
                [self sendPacket:sendPacket toClientWithPeerID:player.peerID];
            }
            break;
        }
        case PacketTypePlaylistItem:
        {
            PlaylistItem *playlistItem = ((PacketPlaylistItem *)packet).playlistItem;
            NSLog(@"Server received playlistItemPacket with song %@", playlistItem.name);
            [self addItemToPlaylist:playlistItem];
            break;
        }
        case PacketTypeMusicDownload:
        {
            // instruction to download music
            NSString *ID = ((PacketMusicDownload *)packet).ID;\
    
            // since they sent the packet, they must have the song
            [player.hasMusicList setObject:@YES forKey:ID];
            
            [self downloadMusicWithID:ID];
            
            break;
        }
        case PacketTypeMusicResponse:
        {
            // means a client has downloaded music
            NSString *ID  = ((PacketMusicResponse *)packet).ID;
            NSLog(@"Server recieved music response packet from player = %@ and ID = %@", player.name, ID);
            
            [player.hasMusicList setObject:@YES forKey:ID];
            MediaItem *mediaItem = (MediaItem *)[self playlistItemWithID:ID];
            [self serverTryPlayingMedia:mediaItem waitTime:WAIT_TIME_DOWNLOAD];
            
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
            playlistItem.justVoted = YES;
            [self.delegate reloadTable];
            
            break;
        }
        case PacketTypeSkipMusic:
        {
            NSLog(@"Server received PacketTypeSkipMusic");
            _skipItemCount++;
            [self.delegate game:self setSkipItemCount:_skipItemCount];
            [self trySkippingSong];
            
            break;
        }
        case PacketTypeCancelMusic:
        {
            NSLog(@"Server received PacketTypeCancelMusic");
            // cancel the song
            NSString *ID = ((PacketCancelMusic *)packet).ID;
            PlaylistItem *playlistItem = [self playlistItemWithID:ID];
            [self cancelMusic:playlistItem];
            
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

- (void)startupRoutineForPlayer:(Player *)player
{
    NSAssert(self.isServer, @"Client in startupRoutineForPlayer");
    
    [self sendGameStatePacket];
    
    for(PlaylistItem *playlistItem in self.playlist) {
        NSLog(@"Updating player = %@ with item = %@", player.name, [playlistItem description]);
        
        // only update if you have fully loaded the song
        if(playlistItem.playlistItemType == PlaylistItemTypeSong && playlistItem.loadProgress == 1.0) {
            PacketMusicDownload *packet = [PacketMusicDownload packetWithID:playlistItem.ID];
            [self sendPacket:packet toClientWithPeerID:player.peerID];
        }
    }
    // send packets to sync with the player
    Packet *packet = [Packet packetWithType:PacketTypeSync];
    packet.packetNumber = 0;
    
    //mark when you sent this packet
    player.packetSendTime[0] = [NSDate date];
    [self sendPacket:packet toClientWithPeerID:player.peerID];
}

- (void)uploadMusicWithMediaItem:(MPMediaItem *)song video:(BOOL)isVideo
{
    NSString *songName = [song valueForProperty:MPMediaItemPropertyTitle];
    NSString *artistName = [song valueForProperty:MPMediaItemPropertyArtist];
    NSURL *songURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
    NSString *ID = [self genRandStringLength:6];
    
    MediaItem *mediaItem = [MediaItem mediaItemWithName:songName andSubtitle:artistName andID:ID andDate:[NSDate date] andLocalURL:songURL];
    mediaItem.uploadedByUser = YES;
    mediaItem.isVideo = isVideo;
    [self addItemToPlaylist:mediaItem];
    
    PacketPlaylistItem *packet = [PacketPlaylistItem packetWithPlaylistItem:mediaItem];
    [self sendPacketToAllClients:packet];
    
    NSURL *assetURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
    
    [_uploader convertAndUpload:mediaItem
                   withAssetURL:assetURL
                   andSessionID:_serverPeerID progress:^{
        [self.delegate reloadPlaylistItem:mediaItem];
    } completion:^ {
        // reload one last time to make sure the progress bar is gone
        [self.delegate reloadTable];
        
        [self hasDownloadedMusic:mediaItem];
        
        NSLog(@"Sending music download packet with: %@", [mediaItem description]);
        PacketMusicDownload *packet = [PacketMusicDownload packetWithID:ID];
        [self sendPacketToAllClients:packet];
        
        // grab beats: PARTY MODE
        NSLog(@"Getting beats for music item with name = %@", mediaItem.name);
        [_downloader downloadBeatsWithMediaItem:mediaItem andSessionID:_serverPeerID completion:^{
            NSLog(@"Found beats for music item with description: %@", [mediaItem description]);
            // update mediaItem
            [mediaItem loadBeats];
        }];
    }];
}
- (void)downloadMusicWithID:(NSString *)ID
{
    //NSLog(@"Recieved music download packet with ID: %@", ID);
    
    // to do: in case you receive this before "PacketTypePlaylistItem"
    MediaItem *mediaItem = (MediaItem *)[self playlistItemWithID:ID];
    NSLog(@"Downloading music item with name = %@", mediaItem.name);
    
    [_downloader downloadFileWithMediaItem:mediaItem andSessionID:_serverPeerID progress:^ {
        [self.delegate reloadPlaylistItem:mediaItem];
    } completion:^{
        NSLog(@"Added music item with description: %@", [mediaItem description]);
        // reload table last time to make sure progress bar is full
        [self.delegate reloadTable];
        
        [self hasDownloadedMusic:mediaItem];
    }];
    
    // PARTY MODE (add a way to turn this off)
    //NSLog(@"Getting beats for music item with name = %@", mediaItem.name);
    [_downloader downloadBeatsWithMediaItem:mediaItem andSessionID:_serverPeerID completion:^{
        //NSLog(@"Found beats for music item with description: %@", [mediaItem description]);
        // update mediaItem
        [mediaItem loadBeats];
    }];
}

- (void)hasDownloadedMusic:(MediaItem *)mediaItem
{
    // this can be called both after someone downloads others' music,
    // and after they have uploaded their own music
    
    if(self.isServer) {
        // mark that you have item
        [((Player *)[_players objectForKey:_session.peerID]).hasMusicList setObject:@YES forKey:mediaItem.ID];
        //NSLog(@"Belonds to user? %@", mediaItem.uploadedByUser ? @"YES" : @"NO");
        if(mediaItem.uploadedByUser) {
            [self serverTryPlayingMedia:mediaItem waitTime:WAIT_TIME_UPLOAD];
        } else {
            [self serverTryPlayingMedia:mediaItem waitTime:WAIT_TIME_DOWNLOAD];
        }
    }
    else {
        // alert the server that you have mediaItem
        PacketMusicResponse *packet = [PacketMusicResponse packetWithSongID:mediaItem.ID];
        [self sendPacketToServer:packet];
    }
}

- (void)addItemToPlaylist:(PlaylistItem *)playlistItem
{
    //NSLog(@"Adding item = %@", [playlistItem description]);
    [_playlist addObject:playlistItem];
    [self.delegate addPlaylistItem:playlistItem];
}

- (void)removeItemFromPlaylist:(PlaylistItem *)playlistItem
{
    [self.delegate game:self setCurrentItem:playlistItem];
    [self.delegate removePlaylistItem:playlistItem animation:UITableViewRowAnimationTop];
}

- (void)cancelMusic:(PlaylistItem *)selectedItem
{
    _gameState = GameStateIdle;
    [self.delegate removePlaylistItem:selectedItem animation:UITableViewRowAnimationRight];
}

- (void)serverTryPlayingMedia:(MediaItem *)mediaItem waitTime:(int)waitTime
{
    NSAssert(self.isServer, @"Client in serverTryPlayingMedia:");
    // this is called on the server whenever someone new downloads the music
    
    if( _gameState == GameStateIdle && [self allPlayersHaveMusic:mediaItem]) {
        _gameState = GameStatePreparingToPlayMedia;
        [_waitTimer invalidate];
        _waitTimer = nil;
        [self serverStartPlayingMedia:mediaItem];
    } else if(_gameState == GameStateIdle) {
        NSLog(@"Created wait timer");
        // create a timer to start playing unless you receive another PacketMusicResponse
        _waitTimer = [NSTimer scheduledTimerWithTimeInterval:waitTime
                                                      target:self
                                                    selector:@selector(handleWaitTimer:)
                                                    userInfo:mediaItem
                                                     repeats:NO];
    }
}

- (void)serverStartPlayingMedia:(MediaItem *)mediaItem {
    NSAssert(self.isServer, @"Client in serverStartPlayingMedia:");
    NSAssert(_gameState == GameStatePreparingToPlayMedia, @"Not correct state in serverStartPlayingMedia:");
    
    NSDate *playTime = [[NSDate date] dateByAddingTimeInterval:DELAY_TIME];
    for (NSString *peerID in _players)
	{
        if([peerID isEqualToString:_serverPeerID]) {
            continue;
        }
		Player *player = [self playerWithPeerID:peerID];
		
        NSDate *theirPlayTime = [playTime dateByAddingTimeInterval:player.timeOffset / player.syncPacketsReceived];
        NSLog(@"Player with timeOffset = %f has playTime = %@", player.timeOffset / player.syncPacketsReceived, theirPlayTime);
        PacketPlayMusicNow *packet = [PacketPlayMusicNow packetWithSongID:mediaItem.ID andTime:theirPlayTime];
        
        [self sendPacket:packet toClientWithPeerID:player.peerID];
    }
    [self playMediaItem:mediaItem withStartTime:playTime];
}

- (void)playMediaItem:(MediaItem *)mediaItem withStartTime:(NSDate *)startTime
{
    NSAssert(_gameState == GameStatePreparingToPlayMedia, @"Not correct state in prepareToPlayMediaItem:");
    
    NSString *tempPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@.m4a", mediaItem.ID];
    NSString *mediaPath = [tempPath stringByAppendingPathComponent:fileName];
    NSURL *mediaURL = [[NSURL alloc] initWithString:mediaPath];
    
    NSError *error;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:mediaURL error:&error];
    _audioPlayer.delegate = self;
    if (_audioPlayer == nil) {
        _gameState = GameStateIdle;
        NSLog(@"AudioPlayer did not load properly: %@", [error description]);
    } else {
        [_audioPlayer prepareToPlay];
        [_audioPlayer play];
        [_audioPlayer stop];
    }
    
    // prime the players many times to see more accurately what our play start time will be
    if(mediaItem.isVideo) {
        _moviePlayer = [[CustomMovieController alloc] initWithContentURL:mediaItem.localURL];
        _moviePlayer.delegate = self;
        
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:mediaURL error:&error];
        if(_moviePlayer == nil) {
            NSLog(@"ERROR loading moviePlayer!");
        }
        _moviePlayer.movieSourceType = MPMovieSourceTypeFile;
        [_moviePlayer prepareToPlay];
        [_moviePlayer pause];
        [_moviePlayer setCurrentPlaybackTime:0];
    }
    
    float compensate = 0.0; // _playStartTime; // _playStartTime is a negative number
    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive) {
        compensate += BACKGROUND_TIME;
        NSLog(@"Application in background.. compensating");
    }
    if(mediaItem.isVideo) {
        compensate += MOVIE_TIME;
    }
    _playMusicTimer = [NSTimer scheduledTimerWithTimeInterval:[startTime timeIntervalSinceNow]+compensate
                                                       target:self
                                                     selector:@selector(playLoadedMediaItem:)
                                                     userInfo:mediaItem
                                                      repeats:NO];
    
    NSLog(@"Playing item, id = %@ with delay = %f", mediaItem.name, [startTime timeIntervalSinceNow]+compensate);
}

- (void)playLoadedMediaItem:(NSTimer *)timer
{
    MediaItem *mediaItem = (MediaItem *)[timer userInfo];
    NSLog(@"Playing item, name = %@", mediaItem.name);
    
    if(_gameState == GameStatePreparingToPlayMedia) {
        // if we're not here, we didn't load the content correctly
        if(mediaItem.isVideo) {
            // call _audioPlayer play, stop to compensate for 
            [_audioPlayer play];
            [_audioPlayer stop];
            _audioPlayer = nil;
            
            [self.delegate addView:_moviePlayer.view];
            [_moviePlayer play];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(moviePlayerDidFinishPlaying:)
                                                         name:MPMoviePlayerPlaybackDidFinishNotification
                                                       object:_moviePlayer];
            _gameState = GameStatePlayingMovie;
        } else {
            [_audioPlayer play];
            _audioPlayerTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                                 target:self
                                                               selector:@selector(updatePlaybackProgress:)
                                                               userInfo:mediaItem
                                                                repeats:YES];
            
            _gameState = GameStatePlayingMusic;
        }				
    }
    
    [self removeItemFromPlaylist:mediaItem];
    
    _haveSkippedThisItem = NO;
    _skipItemCount = 0;
    [self.delegate game:self setSkipItemCount:_skipItemCount];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"AudioPlayer %@ finished playing, success? %@", player == _audioPlayer ? @"audioPlayer" : @"silentPlayer", flag ? @"YES" : @"NO");
    
    if(player == _audioPlayer) {
        NSAssert(!flag || _gameState == GameStatePlayingMusic, @"In audioPlayerDidFinishPlaying:");
        _gameState = GameStateIdle;
        
        [self.delegate setPlaybackProgress:0.0];
        [self.delegate mediaFinishedPlaying];
        [_audioPlayerTimer invalidate];
        _audioPlayerTimer = nil;
        _audioPlayer = nil;
        [self tryPlayingNextItem];
    }
}

- (void)moviePlayerDidFinishPlaying:(MPMoviePlayerController *)player
{
    NSAssert(_gameState == GameStatePlayingMovie, @"In moviePlayerDidFinishPlaying:");
    _gameState = GameStateIdle;
    
    NSLog(@"MoviePlayerDidFinishPlaying");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_moviePlayer stop];
    [_moviePlayer.view removeFromSuperview];
    _moviePlayer = nil;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
    [self.delegate setPlaybackProgress:0.0];
    [self.delegate mediaFinishedPlaying];
    
    [self tryPlayingNextItem];
}

- (void)skipButtonPressed
{
    if(_gameState != GameStatePlayingMusic && _gameState != GameStatePlayingMovie) {
        NSLog(@"Pressed skip button when nothing is playing"); // this should be ok - because someone can skip when not joined
    }
    if(!_haveSkippedThisItem) {
        _haveSkippedThisItem = YES;
        _skipItemCount++;
        [self.delegate game:self setSkipItemCount:_skipItemCount];
        
        Packet *packet = [Packet packetWithType:PacketTypeSkipMusic];
        [self sendPacketToAllClients:packet];
        
        [self trySkippingSong];
    }
}

- (void)trySkippingSong
{
    // if we exceed half the player count, stop the audio and let the next song play
    if( _players.count / 2 < _skipItemCount) {
        NSLog(@"Skipping song!");
        if(_gameState == GameStatePlayingMusic) {
            [self audioPlayerDidFinishPlaying:_audioPlayer successfully:YES];
        } else if(_gameState == GameStatePlayingMovie) {
            [self moviePlayerDidFinishPlaying:_moviePlayer];
        } else {
            [self tryPlayingNextItem];
        }
    }
}

- (void)tryPlayingNextItem
{
    NSAssert(_gameState == GameStateIdle, @"In tryPlayingNextItem:");
    
    NSLog(@"Trying to play next item");
    if(self.isServer) {
        // try to play the next item on the list that is not loading
        for(PlaylistItem *playlistItem in _playlist) {
            if(playlistItem.loadProgress == 1.0) {
                [self serverTryPlayingMedia:(MediaItem *)playlistItem waitTime:WAIT_TIME_UPLOAD];
                break;
            }
        }
    }
}
#pragma mark - Networking

- (void)sendPacketToAllClients:(Packet *)packet
{
	GKSendDataMode dataMode = packet.sendReliably ? GKSendDataReliable : GKSendDataUnreliable;
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
	GKSendDataMode dataMode = packet.sendReliably ? GKSendDataReliable : GKSendDataUnreliable;
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
	GKSendDataMode dataMode = packet.sendReliably ? GKSendDataReliable : GKSendDataUnreliable;
	NSData *data = [packet data];
	NSError *error;
	if (![_session sendData:data toPeers:[NSArray arrayWithObject:_serverPeerID] withDataMode:dataMode error:&error])
	{
		NSLog(@"Error sending data to server: %@", error);
	}
}

- (void)sendGameStatePacket {
    NSAssert(self.isServer, @"Client in sendGameStatePacket:");
    
    Packet *packet = [PacketGameState packetWithPlayers:_players andPlaylist:_playlist andCurrentItem:[self.delegate getCurrentPlaylistItem] andSkipCount:_skipItemCount];
    [self sendPacketToAllClients:packet];
}

- (void)sendVotePacketForItem:(PlaylistItem *)selectedItem andAmount:(int)amount upvote:(BOOL)upvote {
    PacketVote *packet = [PacketVote packetWithSongID:selectedItem.ID andAmount:amount upvote:upvote];
    [self sendPacketToAllClients:packet];
}

- (void)sendCancelMusicPacket:(PlaylistItem *)selectedItem
{
    PacketCancelMusic *packet = [PacketCancelMusic packetWithID:selectedItem.ID];
    [self sendPacketToAllClients:packet];
}


#pragma mark - Utility

- (NSString *)displayNameForPeerID:(NSString *)peerID
{
	return [_session displayNameForPeer:peerID];
}

- (int)indexForPlaylistItem:(PlaylistItem *)playlistItem
{
    for(int i = 0; i < self.playlist.count; i++) {
        if(self.playlist[i] == playlistItem) {
            return i;
        }
    }
    return -1;
}
- (Player *)playerWithPeerID:(NSString *)peerID
{
	return [_players objectForKey:peerID];
}


- (BOOL)allPlayersHaveMusic:(MediaItem *)mediaItem
{
    for (NSString *peerID in _players) {
		Player *player = [self playerWithPeerID:peerID];
		if (![player.hasMusicList objectForKey:mediaItem.ID]) {
			return NO;
        }
	}
    return YES;
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


#pragma mark - Time Utilities

- (void)updatePlaybackProgress:(NSTimer *)timer {
    float total = _audioPlayer.duration;
    float fraction = _audioPlayer.currentTime / total;
    
    [self.delegate setPlaybackProgress:fraction];
    
    // decide whether to mark a beat
    MediaItem *mediaItem = (MediaItem *)timer.userInfo;
    if (mediaItem.beatPos >= 0 && mediaItem.beatPos < [mediaItem.beats count] &&[(NSNumber *)[mediaItem.beats objectAtIndex:mediaItem.beatPos] doubleValue] < _audioPlayer.currentTime) {
        // play a beat
        //NSLog(@"%f is the time; %@ is the beat", _audioPlayer.currentTime, (NSNumber*)[mediaItem.beats objectAtIndex:mediaItem.beatPos]);
        [mediaItem nextBeat];
    }
}

- (void)handleWaitTimer:(NSTimer *)timer {
    NSAssert(self.isServer, @"Client in handleWaitTimer");
    
    NSLog(@"Wait timer called! Playing music");
    if(_gameState != GameStateIdle) {
        return;
    }
    _gameState = GameStatePreparingToPlayMedia;
    
    // means you should start playing MediaItem
    MediaItem *mediaItem = (MediaItem *)[timer userInfo];
    
    [self serverStartPlayingMedia:mediaItem];
    
    if(!mediaItem.uploadedByUser) {
        [mediaItem cancel];
    }
}

#pragma mark - End Session Handling

- (void)destroyFilesWithSessionID:(NSString *)sessionID
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@airshare-destroy.php?sessionid=%@", BASE_URL, sessionID]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if(error) {
            NSLog(@"Error destroying files: %@", error);
        } else {
            NSLog(@"Files with sessionid = %@ destroyed", sessionID);
        }
    }];
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
    [_moviePlayer stop];
	[_session disconnectFromAllPeers];
    
	[self.delegate gameSessionDidEnd:self];
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
    [_moviePlayer stop];
    _audioPlayer = nil;
    _moviePlayer = nil;
	[self.delegate game:self didQuitWithReason:reason];
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
                NSLog(@"Quitting game because server disconnected");
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

- (void)clientDidConnect:(NSString *)peerID
{
    if([_players objectForKey:peerID] == nil) {
        Player *player = [[Player alloc] init];
        player.peerID = peerID;
        [_players setObject:player forKey:player.peerID];
        [self.delegate game:self clientDidConnect:player];
        [self.delegate game:self setSkipItemCount:_skipItemCount];
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
        [self.delegate game:self clientDidDisconnect:player];
        [self.delegate game:self setSkipItemCount:_skipItemCount];
    }
}


@end