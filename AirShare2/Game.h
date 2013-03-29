#import <GameKit/GameKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#import "MatchmakingServer.h"
#import "MusicItem.h"
#import "Player.h"
#import "MusicUpload.h"
#import "MusicDownload.h"
#import "Packet.h"

typedef enum
{
	ServerStateIdle,
	ServerStateAcceptingConnections,
	ServerStateIgnoringNewConnections,
}
ServerState;

@class Game;

@protocol GameDelegate <NSObject>

- (void)game:(Game *)game didQuitWithReason:(QuitReason)reason;

- (void)reloadTable;

- (void)game:(Game *)game setCurrentItem:(PlaylistItem *)playlistItem;

- (void)gameServer:(Game *)server clientDidConnect:(Player *)player;
- (void)gameServer:(Game *)server clientDidDisconnect:(Player *)player;
- (void)gameServerSessionDidEnd:(Game *)server;
- (void)gameServerNoNetwork:(Game *)server;

- (PlaylistItem *)getCurrentPlaylistItem;
- (void)setPlaybackProgress:(double)f;
@end

@interface Game : NSObject <GKSessionDelegate, AVAudioPlayerDelegate> {
    MusicUpload *_uploader;
    MusicDownload *_downloader;
    
    NSTimer *_audioPlayerTimer, *_waitTimer;
    AVAudioPlayer *_audioPlayer;
    NSMutableURLRequest *_serverTimeRequest;
    BOOL _audioPlaying;
}

@property (nonatomic, weak) id <GameDelegate> delegate;
@property (nonatomic, assign) BOOL isServer;
@property (nonatomic, assign) int maxClients;
@property (nonatomic, strong) NSMutableDictionary *players;
@property (nonatomic, strong) NSMutableArray *playlist;
@property (nonatomic, strong) GKSession *session;

- (void)startClientGameWithSession:(GKSession *)session playerName:(NSString *)name server:(NSString *)peerID;
- (void)startServerGameWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients;

- (void)quitGameWithReason:(QuitReason)reason;
- (void)endSession;
- (void)stopAcceptingConnections;

- (NSString *)displayNameForPeerID:(NSString *)peerID;

- (void)addItemToPlaylist:(PlaylistItem *)playlistItem;
- (void)uploadMusicWithMediaItem:(MPMediaItem *)song;
- (void)hasDownloadedMusic:(MusicItem *)musicItem;
- (void)sendVotePacketForItem:(PlaylistItem *)selectedItem andAmount:(int)amount upvote:(BOOL)upvote;
@end