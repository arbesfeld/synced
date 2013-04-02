const size_t PACKET_HEADER_SIZE;

//all the different types of messages we can send
typedef enum
{
	PacketTypeSignIn = 0x64,           // server to client
    
	PacketTypeOtherClientQuit,         // server to client
	PacketTypeServerQuit,              // server to client
	PacketTypeClientQuit,              // client to server
    PacketTypeSkipMusic,               // everyone to everyone
    
    PacketTypeGameState,               // server to client
    PacketTypePlaylistItem,            // client to everyone
    PacketTypeMusicDownload,           // server to client and client to server
    PacketTypeMusicResponse,           // client to server
    PacketTypePlayMusicNow,            // server to client
    PacketTypeVote,                     // client to server
}
PacketType;

const size_t PACKET_HEADER_SIZE;

@interface Packet : NSObject

@property (nonatomic, assign) PacketType packetType;
@property (nonatomic, assign) int packetNumber;

+ (id)packetWithType:(PacketType)packetType;
+ (id)packetWithData:(NSData *)data;
- (id)initWithType:(PacketType)packetType;

- (NSData *)data;

@end