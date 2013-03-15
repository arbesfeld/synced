#import <GameKit/GameKit.h>
#import "MatchmakingServer.h"
#import "Player.h"

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
- (void)gameWaitingForServerReady:(Game *)game;
- (void)gameWaitingForClientsReady:(Game *)game;

- (void)matchmakingServer:(Game *)server clientDidConnect:(NSString *)peerID;
- (void)matchmakingServer:(Game *)server clientDidDisconnect:(NSString *)peerID;
- (void)matchmakingServerSessionDidEnd:(Game *)server;
- (void)matchmakingServerNoNetwork:(Game *)server;

@end

@interface Game : NSObject <GKSessionDelegate>

@property (nonatomic, strong, readonly) NSArray *connectedClients;
@property (nonatomic, weak) id <GameDelegate> delegate;
@property (nonatomic, assign) BOOL isServer;
@property (nonatomic, assign) int maxClients;

- (void)startClientGameWithSession:(GKSession *)session playerName:(NSString *)name server:(NSString *)peerID;
- (void)quitGameWithReason:(QuitReason)reason;
- (void)startServerGameWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients;

- (void)endSession;
- (void)startAcceptingConnectionsForSessionID:(NSString *)sessionID;
- (NSUInteger)connectedClientCount;
- (NSString *)peerIDForConnectedClientAtIndex:(NSUInteger)index;
- (NSString *)displayNameForPeerID:(NSString *)peerID;
- (void)stopAcceptingConnections;

@end