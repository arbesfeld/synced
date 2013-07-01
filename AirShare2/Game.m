#import <GameKit/GameKit.h>

#import "Game.h"
#import "AFNetworking.h"
#import "MusicUpload.h"
#import "Appirater.h"

#import "Packet.h"
#import "PacketSignIn.h"
#import "PacketGameState.h"
#import "PacketOtherClientQuit.h"
#import "PacketMusicDownload.h"
#import "PacketMusicResponse.h"
#import "PacketPlayMusic.h"
#import "PacketVote.h"
#import "PacketPlaylistItem.h"
#import "PacketSyncResponse.h"
#import "PacketCancelMusic.h"

const double DELAY_TIME = 3.5;   // wait DELAY_TIME seconds until songs play
const double DELAY_TIME_YOUTUBE = 6.00000;   // wait DELAY_TIME seconds until youtube songs play
const int WAIT_TIME_UPLOAD = 60;     // server wait time for others to download music after uploading
const int WAIT_TIME_DOWNLOAD = 45;   // server wait time for others to download music after downloading
const int SYNC_PACKET_COUNT = 100;   // how many sync packets to send
const int UPDATE_TIME_AUDIO = 45;    // how often to update playback (after first update)
const int UPDATE_TIME_MOVIE = 45;    // how often to update playback (after first update)
const int UPDATE_TIME_YOUTUBE = 30;  // how often to update playback (after first update)
const int UPDATE_TIME_YOUTUBE_LOADING = 10;   // how often to update playback (after first update)
const int UPDATE_TIME_FIRST = 1;     // how often to update playback (first update)
const double BACKGROUND_TIME = -0.2; // the additional time it takes when app is in background
const double MOVIE_TIME = -0.15;      // the additional time it takes for movies
const double AUDIO_SEEK_TIME = 0.12; // time for audioplayer to seek
const double MOVIE_SEEK_TIME = 0.25; // time for movie player to seek

typedef enum
{
    GameStateSigningIn,
    GameStateIdle,
    GameStatePreparingToPlayMedia,
    GameStatePlayingMusic,
    GameStatePlayingMovie,
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
    
    NSTimer *_playMusicTimer;              // play music after a delay
    NSTimer *_updateMusicTimer;            // update music playback after a delay
    NSTimer *_loadTimeoutTimer;            // play music of down/upload takes too long
    NSTimer *_updatePlaybackProgressTimer; // update playback progress
    NSTimer *_playbackSyncingTimer;        // update syncing
    
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
    
    _partyMode = NO;
    _currentItem = [[PlaylistItem alloc] initPlaylistItemWithName:@"" andSubtitle:@"" andID:@"" andDate:nil andPlaylistItemType:PlaylistItemTypeNone];
    _currentItem.loadProgress = 0.0;
    
    self.maxClients = 4;
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    // app works in background if you start playing the audio player... weird
    NSString *emptyPath = [[NSBundle mainBundle] pathForResource:@"empty" ofType:@"mp3"];
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:emptyPath] error:nil];
    [_audioPlayer play];
    [_audioPlayer stop];
    _audioPlayer = nil;
    
    [self.delegate testBluetooth];
    [self.delegate testInternetConnection];
}

- (void)startClientGameWithSession:(GKSession *)session playerName:(NSString *)name server:(NSString *)peerID
{
    [self startGame];
    
    _gameState = GameStateSigningIn;
	self.isServer = NO;
    
	_session = session;
	_session.available = NO;
	_session.delegate = self;
    
	[_session setDataReceiveHandler:self withContext:nil];
    
	_serverPeerID = peerID;
	_localPlayerName = name;
    
    Packet *packet = [PacketSignIn packetWithPlayerName:_localPlayerName];
	[self sendPacketToServer:packet];
    
    [self.delegate setSkipItemCount:0];
#ifdef DEBUG
    [self updateServerStats:1];
#endif
    
}

- (void)startServerGameWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients
{
    [self startGame];
    
    _gameState = GameStateIdle;
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
    [self.delegate setSkipItemCount:0];
    
#ifdef DEBUG
    [self updateServerStats:1];
#endif
    
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
            NSLog(@"Client received GameStatePacket");
            
            _gameState = GameStateIdle;
            
            [self.players removeAllObjects];
            self.players = ((PacketGameState *)packet).players;
            
            for(PlaylistItem *playlistItem in ((PacketGameState *)packet).playlist) {
                PlaylistItem *inMyPlaylist = [self playlistItemWithID:playlistItem.ID];
                if(inMyPlaylist) {
                    // update the item in my playlist
                    [inMyPlaylist setUpvoteCount:[playlistItem getUpvoteCount]
                                andDownvoteCount:[playlistItem getDownvoteCount]];
                } else {
                    [self.playlist addObject:playlistItem];
                    [self.delegate addPlaylistItem:playlistItem];
                }
            }
            
            PlaylistItem *currentItem = ((PacketGameState *)packet).currentPlaylistItem;
            if(currentItem) {
                [self.delegate setCurrentItem:currentItem];
            }
            
            _skipItemCount = ((PacketGameState *)packet).skipCount;
            [self setSkipCount];
            
            // respond that you are ready
            Packet *packet = [Packet packetWithType:PacketTypeSignInResponse];
            [self sendPacketToServer:packet];
            
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
            NSLog(@"Client received PlaylistItemPacket with song %@", playlistItem.name);
            [self addItemToPlaylist:playlistItem];
            break;
        }
        case PacketTypeMusicDownload:
        {
            NSString *ID = ((PacketMusicDownload *)packet).ID;
            [self downloadMusicWithID:ID];
            break;
        }
        case PacketTypePlayMusic:
        {
            // instruction to play music
            NSString *ID = ((PacketPlayMusic *)packet).ID;
            NSDate *time = ((PacketPlayMusic *)packet).time;
            int songTime = ((PacketPlayMusic *)packet).songTime;
            
            NSLog(@"Client received PacketTypePlayMusic. id = %@, time = %@, songTime = %d", ID, time, songTime);
            MediaItem *mediaItem = (MediaItem *)[self playlistItemWithID:ID];
            
            if(mediaItem == _currentItem) {
                // it is likely the current item
                if(songTime != 0 && _gameState == GameStateIdle) {
                    NSLog(@"Joined in the middle of a song!");
                    // we joined during the middle of a song
                    if(mediaItem.loadProgress == 1.0 || mediaItem.playlistItemType == PlaylistItemTypeYoutube) {
                        _gameState = GameStatePreparingToPlayMedia;
                        
                        if(mediaItem.playlistItemType == PlaylistItemTypeYoutube) {
                            _moviePlayerController = [[CustomMovieController alloc] initWithMediaItem:mediaItem];
                            _moviePlayerController.delegate = self;
                            NSLog(@"loaded with url = %@", mediaItem.url);
                            if(_moviePlayerController.moviePlayer == nil) {
                                _gameState = GameStateIdle;
                                NSLog(@"ERROR loading moviePlayer!");
                            }
                        } else {
                            // it must be audio
                            [self loadAudioPlayer:mediaItem];
                            [_audioPlayer setVolume:0.0];
                        }
                        
                        // this is a bit hacky: act like you're playing the song from the beginning
                        // but set the volume to 0 because it wont be synced
                        _playMusicTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                           target:self
                                                                         selector:@selector(handlePlayMusicTimer:)
                                                                         userInfo:mediaItem
                                                                          repeats:NO];
                    }
                }
            }
            if(songTime == 0) {
                _gameState = GameStatePreparingToPlayMedia;
            }
            [self playMediaItem:mediaItem withStartTime:time atSongTime:songTime];
            
            break;
        }
        case PacketTypeVote:
        {
            // client has voted
            NSString *ID  = ((PacketVote *)packet).ID;
            int amount  = [((PacketVote *)packet) getAmount];
            BOOL upvote  = [((PacketVote *)packet) getUpvote];
            NSLog(@"Client received vote, ID = %@, amount = %d, upvote = %@", ID, amount, upvote == YES ? @"YES" : @"NO");
            
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
            [self setSkipCount];
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
            NSLog(@"Server received sign in from client '%@'", player.name);
            [self sendGameStatePacket];
            
			break;
        }
        case PacketTypeSignInResponse:
        {
            [self startupRoutineForPlayer:player];
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
            
            //NSLog(@"Received sync response with timeOffset = %f", timeOffset);
            
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
            NSLog(@"Server received PlaylistItemPacket with song %@", playlistItem.name);
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
            NSLog(@"Server recieved MusicResponsePacket from player = %@ and ID = %@", player.name, ID);
            
            [player.hasMusicList setObject:@YES forKey:ID];
            MediaItem *mediaItem = (MediaItem *)[self playlistItemWithID:ID];
            [self serverTryPlayingMedia:mediaItem waitTime:WAIT_TIME_DOWNLOAD];
            
            if(mediaItem == _currentItem) {
                NSLog(@"Someone just downloaded the current item.");
                // someone just downloaded the currentItem, update them
                [self sendSyncPacketsForItem:mediaItem];
            }
            break;
        }
        case PacketTypePlayMusicRequest:
        {
            NSLog(@"Request for sync packets");
            // someone wants you to send sync packets
            if([_currentItem isKindOfClass:[MediaItem class]]) {
                [self sendSyncPacketsForItem:(MediaItem *)_currentItem];
            }
            
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
            [self setSkipCount];
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
    
    // maybe send the currentItem
    if((_currentItem.playlistItemType == PlaylistItemTypeSong ||
        _currentItem.playlistItemType == PlaylistItemTypeMovie ||
        _currentItem.playlistItemType == PlaylistItemTypeYoutube) &&
       _currentItem.loadProgress == 1.0 &&
       _gameState != GameStateIdle) {
        NSLog(@"Sending current item that has ID = %@", _currentItem.ID);
        PacketMusicDownload *packet = [PacketMusicDownload packetWithID:_currentItem.ID];
        [self sendPacket:packet toClientWithPeerID:player.peerID];
    }
    
    for(PlaylistItem *playlistItem in self.playlist) {
        NSLog(@"Updating player = %@ with item = %@", player.name, [playlistItem description]);
        
        // only update if you have fully loaded the song and it is not finished
        if((playlistItem.playlistItemType == PlaylistItemTypeSong ||
            playlistItem.playlistItemType == PlaylistItemTypeMovie ||
            playlistItem.playlistItemType == PlaylistItemTypeYoutube) &&
            (playlistItem.loadProgress == 1.0 || !playlistItem.uploadedByUser)) {
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
    [Appirater userDidSignificantEvent:YES];
    NSString *songName = [song valueForProperty:MPMediaItemPropertyTitle];
    NSString *artistName = [song valueForProperty:MPMediaItemPropertyArtist];
    NSInteger mediaType = [[song valueForProperty:MPMediaItemPropertyMediaType] intValue];
    if (mediaType > MPMediaTypeAnyAudio && !isVideo) {
        return;
    }
    NSURL *url = [song valueForProperty:MPMediaItemPropertyAssetURL];
    if(!songName) {
        songName = @"";
    }
    if(!artistName) {
        artistName = @"";
    }
    if(!url) {
        return;
    }
    NSString *ID = [self genRandStringLength:6];
    
    PlaylistItemType type = isVideo ? PlaylistItemTypeMovie : PlaylistItemTypeSong;
    MediaItem *mediaItem = [MediaItem mediaItemWithName:songName
                                            andSubtitle:artistName
                                                  andID:ID
                                                andDate:[NSDate date]
                                                 andURL:url
                                         uploadedByUser:YES
                                    andPlayListItemType:type];
    
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
        
        // PARTY MODE
        NSLog(@"Getting beats for music item with name = %@", mediaItem.name);
        [self downloadBeats:mediaItem];
    } failure:^ {
        [self.delegate cancelMusicAndUpdateAll:mediaItem];
        [self.delegate testInternetConnection];
    }];
}

- (void)downloadBeats:(MediaItem *)mediaItem {
    [_downloader downloadBeatsWithMediaItem:mediaItem andSessionID:_serverPeerID completion:^{
        NSLog(@"Found beats for music item with description: %@", [mediaItem description]);
        // update mediaItem
        [mediaItem loadBeats];
    }];
}

- (void)uploadYoutubeItem:(MediaItem *)youtubeItem
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@",youtubeItem.url]];
    youtubeItem.url = url;
    
    LBYouTubeVideoQuality quality = IS_PHONE ? LBYouTubeVideoQualitySmall : LBYouTubeVideoQualityMedium;
    LBYouTubeExtractor* extractor = [[LBYouTubeExtractor alloc] initWithURL:youtubeItem.url andID:youtubeItem.ID quality:quality];
    extractor.delegate = self;
    [extractor startExtracting];
    
    [self addItemToPlaylist:youtubeItem];
    
    //[self.delegate reloadTable];
}

- (void)youTubeExtractor:(LBYouTubeExtractor *)extractor didSuccessfullyExtractYouTubeURL:(NSURL *)videoURL
{
    NSLog(@"loaded");
    MediaItem *youtubeItem = (MediaItem *)[self playlistItemWithID:extractor.ID];
    youtubeItem.loadProgress = 1.0;
    [self.delegate reloadPlaylistItem:youtubeItem];
    
    if(youtubeItem.uploadedByUser) {
        PacketPlaylistItem *packet = [PacketPlaylistItem packetWithPlaylistItem:youtubeItem];
        [self sendPacketToAllClients:packet];
        
        NSLog(@"Sending music download packet with: %@", [youtubeItem description]);
        PacketMusicDownload *downloadPacket = [PacketMusicDownload packetWithID:youtubeItem.ID];
        [self sendPacketToAllClients:downloadPacket];
    }
    youtubeItem.url = videoURL;
    [self hasDownloadedMusic:youtubeItem];
}

- (void)youTubeExtractor:(LBYouTubeExtractor *)extractor failedExtractingYouTubeURLWithError:(NSError *)error
{
    MediaItem *youtubeItem = (MediaItem *)[self playlistItemWithID:extractor.ID];
    [self.delegate cancelMusicAndUpdateAll:youtubeItem];
    
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Protected Content", @"Protected Content alert view")
                              message:NSLocalizedString(@"Sorry, Synced can't play YouTube videos that contain DRM.", @"Protectect Content alert message")
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", @"Button: OK")
                              otherButtonTitles:nil];
    [alertView show];
}

- (void)downloadMusicWithID:(NSString *)ID
{
    //NSLog(@"Recieved music download packet with ID: %@", ID);
    
    // to do: in case you receive this before "PacketTypePlaylistItem"
    MediaItem *mediaItem = (MediaItem *)[self playlistItemWithID:ID];
    NSLog(@"Downloading music item with name = %@", mediaItem.name);
    
    if(mediaItem.playlistItemType == PlaylistItemTypeYoutube) {
        NSLog(@"loading item with url = %@", mediaItem.url);
        LBYouTubeExtractor* extractor = [[LBYouTubeExtractor alloc] initWithURL:mediaItem.url andID:mediaItem.ID quality:LBYouTubeVideoQualityLarge];
        extractor.delegate = self;
        [extractor startExtracting];
        
        return;
    }
    
    [_downloader downloadFileWithMediaItem:mediaItem andSessionID:_serverPeerID progress:^ {
        [self.delegate reloadPlaylistItem:mediaItem];
    } completion:^ {
        NSLog(@"Added music item with description: %@", [mediaItem description]);
        // reload table last time to make sure progress bar is full
        [self.delegate reloadTable];
        
        [self hasDownloadedMusic:mediaItem];
    } failure:^ {
        if(self.isServer) {
            [self.delegate cancelMusicAndUpdateAll:mediaItem];
        } else {
            [self hasDownloadedMusic:mediaItem];
            [self.delegate testInternetConnection];
        }
    }];
    
    // PARTY MODE
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


- (void)serverTryPlayingMedia:(MediaItem *)mediaItem waitTime:(int)waitTime
{
    // this is called on the server whenever someone new downloads the music
    
    NSAssert(self.isServer, @"Client in serverTryPlayingMedia:");
    
    // if the media item is not in the playlist, it has already been played
    // and we can skip this call
    if ([self indexForPlaylistItem:mediaItem] == -1) {
        return;
    }
    
    if ( _gameState == GameStateIdle && [self allPlayersHaveMusic:mediaItem]) {
        _gameState = GameStatePreparingToPlayMedia;
        
        [_loadTimeoutTimer invalidate];
        _loadTimeoutTimer = nil;
        [self serverStartPlayingMedia:mediaItem];
    } else if (_gameState == GameStateIdle) {
        NSLog(@"Created wait timer");
        // create a timer to start playing unless you receive another PacketMusicResponse
        if(!_loadTimeoutTimer) {
            _loadTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:waitTime
                                                                 target:self
                                                               selector:@selector(handleLoadTimeoutTimer:)
                                                               userInfo:mediaItem
                                                                repeats:NO];
        }
    }
}

- (void)serverStartPlayingMedia:(MediaItem *)mediaItem {
    NSAssert(self.isServer, @"Client in serverStartPlayingMedia:");
    NSAssert(_gameState == GameStatePreparingToPlayMedia, @"Not correct state in serverStartPlayingMedia:");
    
    [self removeItemFromPlaylistAndSetCurrent:mediaItem];
    
    double delayTime = mediaItem.playlistItemType == PlaylistItemTypeYoutube ? DELAY_TIME_YOUTUBE : DELAY_TIME;
    NSDate *playTime = [[NSDate date] dateByAddingTimeInterval:delayTime];
    for (NSString *peerID in _players)
	{
        if([peerID isEqualToString:_serverPeerID]) {
            continue;
        }
		Player *player = [self playerWithPeerID:peerID];
		
        NSDate *theirPlayTime = [playTime dateByAddingTimeInterval:player.timeOffset / player.syncPacketsReceived];
        NSLog(@"Player with timeOffset = %f has playTime = %@", player.timeOffset / player.syncPacketsReceived, theirPlayTime);
        PacketPlayMusic *packet = [PacketPlayMusic packetWithSongID:mediaItem.ID andTime:theirPlayTime atSongTime:0];
        [self sendPacket:packet toClientWithPeerID:player.peerID];
    }
    [self playMediaItem:mediaItem withStartTime:playTime atSongTime:0];
}

- (void)playMediaItem:(MediaItem *)mediaItem withStartTime:(NSDate *)startTime atSongTime:(int)songTime
{
    float compensate = 0.0;
    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive) {
        compensate += BACKGROUND_TIME;
        NSLog(@"Application inactive.. compensating");
    }
    if(mediaItem.playlistItemType == PlaylistItemTypeMovie && mediaItem.uploadedByUser) {
        compensate += MOVIE_TIME;
    }
    
    if(songTime == 0) {
        NSAssert(_gameState == GameStatePreparingToPlayMedia, @"Not correct state in prepareToPlayMediaItem:");
    
        [self removeItemFromPlaylistAndSetCurrent:mediaItem];
        
        // if you are starting the song for the first time
        if((mediaItem.playlistItemType == PlaylistItemTypeMovie && mediaItem.uploadedByUser) ||
            mediaItem.playlistItemType == PlaylistItemTypeYoutube) {
#ifdef DEBUG
            if (mediaItem.playlistItemType == PlaylistItemTypeMovie && mediaItem.uploadedByUser) {
                [self updateServerStats:3];
            } else if (mediaItem.uploadedByUser) {
                [self updateServerStats:4]; // Youtube
            }
#endif
            
            if(_audioPlayer) {
                // if the audioPlayer is playing, stop it
                [_audioPlayer stop];
                [self audioPlayerDidFinishPlaying:_audioPlayer successfully:YES];
            }
            
            _moviePlayerController = [[CustomMovieController alloc] initWithMediaItem:mediaItem];
            _moviePlayerController.delegate = self;
            NSLog(@"loaded with url = %@", mediaItem.url);
            if(_moviePlayerController.moviePlayer == nil) {
                _gameState = GameStateIdle;
                NSLog(@"ERROR loading moviePlayer!");
                if(mediaItem.playlistItemType == PlaylistItemTypeMovie) {
                    [self skipSong];
                    return;
                }
            }
            
        
        } else {
            [self loadAudioPlayer:mediaItem];
#ifdef DEBUG
            if (mediaItem.uploadedByUser) {
                [self updateServerStats:2];
            }
#endif
        }
        _playMusicTimer = [NSTimer scheduledTimerWithTimeInterval:[startTime timeIntervalSinceNow] + compensate
                                                           target:self
                                                         selector:@selector(handlePlayMusicTimer:)
                                                         userInfo:mediaItem
                                                          repeats:NO];
    } else {
        if([[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive) {
            return;
        }
        float delay = [startTime timeIntervalSinceNow];
        float songTimeF = (double)songTime;
        if(delay < 0.0) {
            songTimeF = songTime - ABS(delay) + 1.0;
            delay = 1.0;
        }
        _updateMusicTimer = [NSTimer scheduledTimerWithTimeInterval:delay
                                                             target:self
                                                           selector:@selector(handleUpdateMusicTimer:)
                                                           userInfo:[NSNumber numberWithFloat:songTimeF]
                                                            repeats:NO];
    }
    
    NSLog(@"Will play item, name = %@ with delay = %f at song time = %d", mediaItem.name, [startTime timeIntervalSinceNow] + compensate, songTime);
}

- (void)loadAudioPlayer:(MediaItem *)mediaItem {
    if(_moviePlayerController) {
        [self moviePlayerDidFinishPlaying:nil];
    }
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
        [_audioPlayer play];
        [_audioPlayer pause];
    }
}

#pragma mark - PlaylistManagement

- (void)addItemToPlaylist:(PlaylistItem *)playlistItem
{
    //NSLog(@"Adding item = %@", [playlistItem description]);
    [_playlist addObject:playlistItem];
    [self.delegate addPlaylistItem:playlistItem];
}

- (void)removeItemFromPlaylistAndSetCurrent:(PlaylistItem *)playlistItem
{
    [self.delegate setCurrentItem:playlistItem];
    [self.delegate removePlaylistItem:playlistItem animation:NO];
}

- (void)cancelMusic:(PlaylistItem *)selectedItem
{
    //_gameState = GameStateIdle;
    [self.delegate removePlaylistItem:selectedItem animation:YES];
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"AudioPlayer %@ finished playing, success? %@", player == _audioPlayer ? @"audioPlayer" : @"silentPlayer", flag ? @"YES" : @"NO");
    
    if(player == _audioPlayer) {
        _gameState = GameStateIdle;
        
        if(_updatePlaybackProgressTimer) {
            [_updatePlaybackProgressTimer invalidate];
            _updatePlaybackProgressTimer = nil;
        }
        if(_playbackSyncingTimer) {
            [_playbackSyncingTimer invalidate];
            _playbackSyncingTimer = nil;
        }
        
        [self.delegate mediaFinishedPlaying];
        _audioPlayer = nil;
        [self tryPlayingNextItem];
    }
}

- (void)moviePlayerDidFinishPlaying:(AVPlayerItem *)playerItem
{
    NSLog(@"MoviePlayerDidFinishPlaying");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_moviePlayerController stop];
    if([_moviePlayerController isViewLoaded]) {
        [_moviePlayerController dismissViewControllerAnimated:NO completion:^ {
            _moviePlayerController = nil;
        }];
    } else {
        _moviePlayerController = nil;
    }
    
    if(_updatePlaybackProgressTimer) {
        [_updatePlaybackProgressTimer invalidate];
        _updatePlaybackProgressTimer = nil;
    }
    if(_playbackSyncingTimer) {
        [_playbackSyncingTimer invalidate];
        _playbackSyncingTimer = nil;
    }
    
    if(_gameState != GameStatePlayingMovie) {
        // we already started new content
        return;
    }
    
    [self.delegate mediaFinishedPlaying];
    _gameState = GameStateIdle;
    
    [self tryPlayingNextItem];
}

- (void)skipButtonPressed
{
    NSLog(@"Skip button pressed");
    if(_gameState != GameStatePlayingMusic && _gameState != GameStatePlayingMovie) {
        NSLog(@"Pressed skip button when nothing is playing"); // this should be ok - because someone can skip when not joined
    }
    if(_gameState == GameStatePreparingToPlayMedia) {
        NSLog(@"Pressed skip button when preparing to play media!");
        // we don't want them to skip during this period
        return;
    }
    if(!_haveSkippedThisItem) {
        NSLog(@"Haven't skipped this item");
        _haveSkippedThisItem = YES;
        _skipItemCount++;
        [self setSkipCount];
        
        Packet *packet = [Packet packetWithType:PacketTypeSkipMusic];
        [self sendPacketToAllClients:packet];
        
        [self trySkippingSong];
    }
}

- (void)trySkippingSong
{
    // if we exceed half the player count, stop the audio and let the next song play
    if( _players.count / 2 < _skipItemCount) {
        [self skipSong];
    }
}

- (void)skipSong
{
#ifdef DEBUG
    if (((MediaItem *)_currentItem).uploadedByUser) {
        [self updateServerStats:5];
    }
#endif
    
    NSLog(@"Skipping song!");
    [self.delegate setSkipItemCount:0];
    [self.delegate mediaFinishedPlaying];
    
    if(_gameState == GameStatePlayingMusic) {
        [self audioPlayerDidFinishPlaying:_audioPlayer successfully:YES];
    } else if(_gameState == GameStatePlayingMovie) {
        [self moviePlayerDidFinishPlaying:nil];
    } else {
        _gameState = GameStateIdle;
        [self tryPlayingNextItem];
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

#pragma mark - Timers

- (void)handlePlayMusicTimer:(NSTimer *)timer
{
    MediaItem *mediaItem = (MediaItem *)[timer userInfo];
    
    if(_gameState == GameStatePreparingToPlayMedia) {
        // if we're here, we loaded the content correctly
        if((mediaItem.playlistItemType == PlaylistItemTypeMovie && mediaItem.uploadedByUser) ||
           mediaItem.playlistItemType == PlaylistItemTypeYoutube) {
            [self.delegate showViewController:_moviePlayerController];
            _updatePlaybackProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                                            target:self
                                                                          selector:@selector(handleUpdatePlaybackProgressTimer:)
                                                                          userInfo:mediaItem
                                                                           repeats:YES];
            // code if you only want youtube video on host:
//            if(mediaItem.uploadedByUser) {
//                NSLog(@"making frame 0");
//                [self.delegate showViewController:_moviePlayerController];
//            } else {
//                _updatePlaybackProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
//                                                                                target:self
//                                                                              selector:@selector(handleUpdatePlaybackProgressTimer:)
//                                                                              userInfo:mediaItem
//                                                                               repeats:YES];
//            }
            [_moviePlayerController.moviePlayer play];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(moviePlayerDidFinishPlaying:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:_moviePlayerController.moviePlayer.playerItem];
            _gameState = GameStatePlayingMovie;
        } else {
    
            [_audioPlayer play]; 
            _updatePlaybackProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                                            target:self
                                                                          selector:@selector(handleUpdatePlaybackProgressTimer:)
                                                                          userInfo:mediaItem
                                                                           repeats:YES];
            
            _gameState = GameStatePlayingMusic;
            
        }
        if(self.isServer) {
            _playbackSyncingTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATE_TIME_FIRST
                                                                     target:self
                                                                   selector:@selector(handlePlaybackSyncingTimer:)
                                                                   userInfo:mediaItem
                                                                    repeats:NO];
            
        }
    }
    
    _haveSkippedThisItem = NO;
    _skipItemCount = 0;
    [self setSkipCount];
    
    NSLog(@"Playing item, name = %@", mediaItem.name);
}

- (void)handleUpdateMusicTimer:(NSTimer *)timer
{
    int songTime = [[timer userInfo] intValue];
    NSLog(@"Updating with song time = %d", songTime);
    if(_gameState == GameStatePlayingMusic) {
        [_audioPlayer setCurrentTime:songTime + AUDIO_SEEK_TIME];
        [_audioPlayer setVolume:1.0]; // turn on the volume when we know we are synced
    } else if(_gameState == GameStatePlayingMovie) {
        CMTime npt = CMTimeMakeWithSeconds(songTime + MOVIE_SEEK_TIME, 600);
        [_moviePlayerController.moviePlayer.player seekToTime:npt toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}

- (void)handlePlaybackSyncingTimer:(NSTimer *)timer
{
    NSAssert(self.isServer, @"Client in handlePlaybackSyncingTimer");
    
    MediaItem *mediaItem = (MediaItem *)[timer userInfo];
    
    [self sendSyncPacketsForItem:mediaItem];
    int UPDATE_TIME = 30;
    switch(mediaItem.playlistItemType) {
        case PlaylistItemTypeSong:
            UPDATE_TIME = UPDATE_TIME_AUDIO;
            break;
        case PlaylistItemTypeMovie:
            UPDATE_TIME = UPDATE_TIME_MOVIE;
            break;
        case PlaylistItemTypeYoutube:
            if(_moviePlayerController && CMTimeGetSeconds([_moviePlayerController.moviePlayer.player currentTime]) < 40) {
                UPDATE_TIME = UPDATE_TIME_YOUTUBE_LOADING;
            } else {
                UPDATE_TIME = UPDATE_TIME_YOUTUBE;
            }
            break;
        default:
            UPDATE_TIME = 30;
            break;
    }
    _playbackSyncingTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATE_TIME
                                                             target:self
                                                           selector:@selector(handlePlaybackSyncingTimer:)
                                                           userInfo:mediaItem
                                                            repeats:NO];
    
}

- (void)handleUpdatePlaybackProgressTimer:(NSTimer *)timer
{
    if(_gameState == GameStateIdle) {
        return;
    }
    
    // decide whether to mark a beat
    MediaItem *mediaItem = (MediaItem *)timer.userInfo;
    
    if(mediaItem.playlistItemType == PlaylistItemTypeSong ||
       (mediaItem.playlistItemType == PlaylistItemTypeMovie && !mediaItem.uploadedByUser)) {
        float total = _audioPlayer.duration;
        float fraction = _audioPlayer.currentTime / total;
        
        [self.delegate setPlaybackProgress:fraction];
        [self.delegate secondsRemaining:total - _audioPlayer.currentTime];
        
        while (_partyMode && mediaItem.beatsLoaded && mediaItem.beatPos >= 0 && mediaItem.beatPos < [mediaItem.beats count] - 1 && [(NSNumber *)[mediaItem.beats objectAtIndex:mediaItem.beatPos + 1] doubleValue] < _audioPlayer.currentTime + 0.05) {
            [mediaItem skipBeat];
        }
        if (_partyMode && mediaItem.beatsLoaded && mediaItem.beatPos >= 0 && mediaItem.beatPos < [mediaItem.beats count] && [(NSNumber *)[mediaItem.beats objectAtIndex:mediaItem.beatPos] doubleValue] < _audioPlayer.currentTime + 0.05) {
            // play a beat
            //NSLog(@"%f ifs the time; %@ is the beat", _audioPlayer.currentTime, (NSNumber*)[mediaItem.beats objectAtIndex:mediaItem.beatPos]);
            
            // don't play the beat if it's too far elapsed
            if ([(NSNumber *)[mediaItem.beats objectAtIndex:mediaItem.beatPos] doubleValue] < _audioPlayer.currentTime + 0.03) {
                [mediaItem skipBeat];
            } else {
                [self.delegate flashScreen:mediaItem.beatPos];
                mediaItem.beatPos++;
            }
        }
    } else if(mediaItem.playlistItemType == PlaylistItemTypeMovie ||
              mediaItem.playlistItemType == PlaylistItemTypeYoutube) {
        float current = CMTimeGetSeconds([_moviePlayerController.moviePlayer.player currentTime]);
        float total = CMTimeGetSeconds(_moviePlayerController.moviePlayer.player.currentItem.asset.duration);
        float fraction = current / total;
        
        [self.delegate setPlaybackProgress:fraction];
        [self.delegate secondsRemaining:total - current];
    }
}

- (void)handleLoadTimeoutTimer:(NSTimer *)timer
{
    NSAssert(self.isServer, @"Client in handleLoadTimeoutTimer");

    NSLog(@"LoadTimeoutTimer called! Playing music");
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

#pragma mark - Packet

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
    
    Packet *packet = [PacketGameState packetWithPlayers:_players
                                            andPlaylist:_playlist
                                         andCurrentItem:_gameState == GameStateIdle ? nil : _currentItem
                                           andSkipCount:_skipItemCount];
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

- (void)sendSyncPacketsForItem:(MediaItem *)mediaItem
{
    if(self.isServer) {
        float delay = 0.0;
        int songTime = 0;
        if(_gameState == GameStatePlayingMovie) {
            songTime = (int)CMTimeGetSeconds([_moviePlayerController.moviePlayer.player currentTime]) + DELAY_TIME;
            if(songTime > CMTimeGetSeconds(_moviePlayerController.moviePlayer.player.currentItem.asset.duration) - 4 * DELAY_TIME) {
                // the song is almost over
                return;
            }
            delay = (float)songTime - CMTimeGetSeconds([_moviePlayerController.moviePlayer.player currentTime]);
        } else if(_gameState == GameStatePlayingMusic) {
            songTime = (int)[_audioPlayer currentTime] + DELAY_TIME;
            if(songTime > [_audioPlayer duration] - 4 * DELAY_TIME) {
                // the movie is almost over
                return;
            }
            delay = (float)songTime - [_audioPlayer currentTime];
        }
        
        if((_gameState == GameStatePlayingMusic || _gameState == GameStatePlayingMovie) && delay != 0.0 && songTime != 0) {
            for (NSString *peerID in _players)
            {
                if([peerID isEqualToString:_serverPeerID]) {
                    continue;
                }
                Player *player = [self playerWithPeerID:peerID];
                
                NSDate *playTime = [[NSDate date] dateByAddingTimeInterval:delay];
                NSDate *theirPlayTime = [playTime dateByAddingTimeInterval:player.timeOffset / player.syncPacketsReceived];
                PacketPlayMusic *packet = [PacketPlayMusic packetWithSongID:mediaItem.ID andTime:theirPlayTime atSongTime:songTime];
                [self sendPacket:packet toClientWithPeerID:player.peerID];
                
                NSLog(@"Updating player with id = %@ has delay = %f for songTime = %d", mediaItem.ID, delay, songTime);
            }
        }
    } else {
        Packet *packet = [Packet packetWithType:PacketTypePlayMusicRequest];
        [self sendPacketToServer:packet];
    }
}

#pragma mark - CustomMovieControllerDelegate

- (BOOL)isPlayingMovie {
    return _gameState == GameStatePlayingMovie;
}

#pragma mark - Utility

/*
 Actions:
 1 - num_users++
 2 - num_songs++
 3 - num_moves++
 4 - num_youtube++
 5 - num_skips++
 6 - num_upvotes++
 7 - num_downvotes++
 8 - num_partymode++
 9 - num_sync++
 */
- (void)updateServerStats:(int)action
{
//    NSString *urlString = [NSString stringWithFormat:@"%@airshare-morestats.php?sessionid=%@&action=%d", BASE_URL, _serverPeerID, action];
//    //NSLog(@"Making url request: %@", urlString);
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
//    [request setHTTPMethod:@"GET"];
//    [request setURL:[NSURL URLWithString:urlString]];
//    
//    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *responseCode, NSData *data, NSError *error) {
//        if(error) {
//            NSLog(@"Error getting %@, HTTP status code %@", urlString, responseCode);
//        }
//    }];
    
}

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
    if([_currentItem.ID isEqualToString:ID]) {
        return _currentItem;
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

- (void)setSkipCount {
    [self.delegate setSkipItemCount:_skipItemCount];
    if(_moviePlayerController) {
        [_moviePlayerController setSkipCount:_skipItemCount total:_players.count];
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
    _uploader = nil;
    _downloader = nil;
    
    [self stopAllTimers];
    [_audioPlayer stop];
    [_moviePlayerController.moviePlayer stop];
	[_session disconnectFromAllPeers];
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
	[self.delegate gameSessionDidEnd:self];
}

- (void)stopAllTimers
{
    [_playMusicTimer invalidate];
    [_updateMusicTimer invalidate];
    [_loadTimeoutTimer invalidate];
    [_updatePlaybackProgressTimer invalidate];
    [_playbackSyncingTimer invalidate];
    _playMusicTimer = nil;
    _updateMusicTimer = nil;
    _loadTimeoutTimer = nil;
    _updatePlaybackProgressTimer = nil;
    _playbackSyncingTimer = nil;
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
    [self stopAllTimers];
    [_audioPlayer stop];
    [_moviePlayerController.moviePlayer stop];
    _audioPlayer = nil;
    _moviePlayerController = nil;
	[self.delegate didQuitWithReason:reason];
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
        [self.delegate clientDidConnect:player];
        [self setSkipCount];
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
        [self.delegate clientDidDisconnect:player];
        [self setSkipCount];
        [self trySkippingSong];
    }
}


@end