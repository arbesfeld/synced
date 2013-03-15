#import "Game.h"
#import "Packet.h"
#import "PacketSignInResponse.h"
#import "PacketPlayerList.h"
#import <GameKit/GameKit.h>

typedef enum
{
	GameStateWaitingForSignIn,
	GameStatePlaying,
	GameStateQuitting,
}
GameState;

@implementation Game
{
	GameState _state;
    
	GKSession *_session;
	NSString *_serverPeerID;
	NSString *_localPlayerName;
    
    NSMutableDictionary *_players;

    NSMutableArray *_connectedClients;
    ServerState _serverState;
}

@synthesize delegate = _delegate;
@synthesize isServer = _isServer;

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
	}
	return self;
}

#pragma mark - Game Logic

- (void)startClientGameWithSession:(GKSession *)session playerName:(NSString *)name server:(NSString *)peerID
{
	self.isServer = NO;
    
	_session = session;
	_session.available = YES;
	_session.delegate = self;
    
    self.maxClients = 4;
    
	[_session setDataReceiveHandler:self withContext:nil];
    
	_serverPeerID = peerID;
	_localPlayerName = name;
    
    Player *player = [[Player alloc] init];
	player.name = _localPlayerName;
	player.peerID = _session.peerID;
    
	[_players setObject:player forKey:player.peerID];
    
	_state = GameStateWaitingForSignIn;
    
    Packet *packet = [Packet packetWithType:PacketTypeSignInRequest];
	[self sendPacketToServer:packet];
}

- (void)startServerGameWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients
{
	self.isServer = YES;
    
	_session = session;
	_session.available = YES;
	_session.delegate = self;
    
    self.maxClients = 4;
    
	[_session setDataReceiveHandler:self withContext:nil];
    
	_state = GameStateWaitingForSignIn;
    _serverState = ServerStateAcceptingConnections;
    
	[self.delegate gameWaitingForClientsReady:self];
    
    Player *player = [[Player alloc] init];
	player.name = name;
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
	if (player != nil)
	{
		player.receivedResponse = YES;  // this is the new bit
	}
    
	if (self.isServer)
		[self serverReceivedPacket:packet fromPlayer:player];
	else
		[self clientReceivedPacket:packet];
}

- (void)clientReceivedPacket:(Packet *)packet
{
	switch (packet.packetType)
	{
		case PacketTypeSignInRequest:
			if (_state == GameStateWaitingForSignIn)
			{
				_state = GameStatePlaying;
                
				//Packet *packet = [PacketSignInResponse packetWithPlayerName:_localPlayerName];
                
				//[self sendPacketToServer:packet];
			}
			break;
            
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
			if (_state == GameStateWaitingForSignIn)
			{
				player.name = ((PacketSignInResponse *)packet).playerName;
                
                _state = GameStatePlaying;
                
                Packet *packet = [PacketPlayerList packetWithPlayers:_players];
                [self sendPacketToAllClients:packet];
                
				NSLog(@"server received sign in from client '%@'", player.name);
			}
			break;
            
		default:
			NSLog(@"Server received unexpected packet: %@", packet);
			break;
	}
}

#pragma mark - Networking

- (void)sendPacketToAllClients:(Packet *)packet
{
    [_players enumerateKeysAndObjectsUsingBlock:^(id key, Player *obj, BOOL *stop)
     {
         obj.receivedResponse = [_session.peerID isEqualToString:obj.peerID];
     }];
    
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
	NSLog(@"MatchmakingServer: peer %@ changed state %d", peerID, state);
    #endif
    if(_isServer) {
        switch (state)
        {
            case GKPeerStateAvailable:
                break;
                
            case GKPeerStateUnavailable:
                break;
                
                // A new client has connected to the server.
            case GKPeerStateConnected:
                if (_serverState == ServerStateAcceptingConnections)
                {
                    if (![_connectedClients containsObject:peerID])
                    {
                        [_connectedClients addObject:peerID];
                        [self.delegate matchmakingServer:self clientDidConnect:peerID];
                    }
                }
                break;
                
                // A client has disconnected from the server.
            case GKPeerStateDisconnected:
                if (_serverState != ServerStateIdle)
                {
                    if ([_connectedClients containsObject:peerID])
                    {
                        [_connectedClients removeObject:peerID];
                        [self.delegate matchmakingServer:self clientDidDisconnect:peerID];
                    }
                }
                break;
                
            case GKPeerStateConnecting:
                break;
        }
    }
}


- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    #ifdef DEBUG
	NSLog(@"MatchmakingServer: connection request from peer %@", peerID);
    #endif
    
	if (_isServer && _serverState == ServerStateAcceptingConnections && [self connectedClientCount] < self.maxClients)
	{
		NSError *error;
		if ([session acceptConnectionFromPeer:peerID error:&error])
			NSLog(@"MatchmakingServer: Connection accepted from peer %@", peerID);
		else
			NSLog(@"MatchmakingServer: Error accepting connection from peer %@, %@", peerID, error);
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
}

- (NSUInteger)connectedClientCount
{
	return [_connectedClients count];
}

- (NSString *)peerIDForConnectedClientAtIndex:(NSUInteger)index
{
	return [_connectedClients objectAtIndex:index];
}

- (NSString *)displayNameForPeerID:(NSString *)peerID
{
	return [_session displayNameForPeer:peerID];
}

- (void)endSession
{
	_serverState = ServerStateIdle;
    
	[_session disconnectFromAllPeers];
	_session.available = NO;
	_session.delegate = nil;
	_session = nil;
    
	_connectedClients = nil;
    
	[self.delegate matchmakingServerSessionDidEnd:self];
}

- (void)stopAcceptingConnections
{
	_serverState = ServerStateIgnoringNewConnections;
	_session.available = NO;
}


- (Player *)playerWithPeerID:(NSString *)peerID
{
	return [_players objectForKey:peerID];
}

- (void)quitGameWithReason:(QuitReason)reason
{
	_state = GameStateQuitting;
    
	[_session disconnectFromAllPeers];
	_session.delegate = nil;
	_session = nil;
    
	[self.delegate game:self didQuitWithReason:reason];
}
@end