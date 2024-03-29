#import <GameKit/GameKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#import "MatchmakingServer.h"
#import "MediaItem.h"
#import "Player.h"
#import "MusicUpload.h"
#import "MusicDownload.h"
#import "Packet.h"
#import "CustomMovieController.h"
#import "LBYouTubeExtractor.h"

typedef enum
{
	ServerStateIdle,
	ServerStateAcceptingConnections,
	ServerStateIgnoringNewConnections,
}
ServerState;

@class Game;

@protocol GameDelegate <NSObject>

- (void)didQuitWithReason:(QuitReason)reason;

- (void)reloadTable;
- (void)reloadPlaylistItem:(PlaylistItem *)playlistItem;
- (void)addPlaylistItem:(PlaylistItem *)playlistItem;
- (void)removePlaylistItem:(PlaylistItem *)playlistItem animation:(BOOL)animation;
- (void)cancelMusicAndUpdateAll:(PlaylistItem *)playlistItem;

- (void)secondsRemaining:(int)secondsRemaining;
- (void)mediaFinishedPlaying;

- (void)setCurrentItem:(PlaylistItem *)playlistItem;
- (void)setSkipItemCount:(int)skipItemCount;

- (void)clientDidConnect:(Player *)player;
- (void)clientDidDisconnect:(Player *)player;

- (void)testInternetConnection;
- (void)testBluetooth;

- (void)gameSessionDidEnd:(Game *)server;
- (void)gameNoNetwork:(Game *)server;

- (void)flashScreen:(int)flashColor;

- (void)setPlaybackProgress:(double)f;

- (void)showViewController:(UIViewController *)viewController;

@end

@interface Game : NSObject <GKSessionDelegate, AVAudioPlayerDelegate, CustomMovieControllerDelegate, LBYouTubeExtractorDelegate> {
}

@property (nonatomic, weak) id <GameDelegate> delegate;
@property (nonatomic, assign) BOOL isServer, partyMode;
@property (nonatomic, assign) int maxClients;
@property (nonatomic, strong) NSMutableDictionary *players;
@property (nonatomic, strong) GKSession *session;

@property (nonatomic, strong) PlaylistItem *currentItem;
@property (nonatomic, strong) NSMutableArray *playlist;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) CustomMovieController *moviePlayerController;

- (void)startClientGameWithSession:(GKSession *)session playerName:(NSString *)name server:(NSString *)peerID;
- (void)startServerGameWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients;

- (void)quitGameWithReason:(QuitReason)reason;
- (void)endSession;
- (void)stopAcceptingConnections;

- (NSString *)displayNameForPeerID:(NSString *)peerID;

- (void)uploadMusicWithMediaItem:(MPMediaItem *)song video:(BOOL)isVideo;
- (void)uploadYoutubeItem:(MediaItem *)youtubeItem;
- (void)skipButtonPressed;
- (void)cancelMusic:(PlaylistItem *)selectedItem;
- (int)indexForPlaylistItem:(PlaylistItem *)playlistItem;

- (void)updateServerStats:(int)action;

- (void)sendVotePacketForItem:(PlaylistItem *)selectedItem andAmount:(int)amount upvote:(BOOL)upvote;
- (void)sendCancelMusicPacket:(PlaylistItem *)selectedItem;
- (void)sendSyncPacketsForItem:(MediaItem *)mediaItem;
@end