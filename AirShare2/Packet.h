const size_t PACKET_HEADER_SIZE;

//all the different types of messages we can send
typedef enum
{
	PacketTypeSignInRequest = 0x64,    // server to client
	PacketTypeSignInResponse,          // client to server
    
    PacketTypePlayerList,              // server to client
    
	PacketTypeServerReady,             // server to client
	PacketTypeClientReady,             // client to server
    
	PacketTypeOtherClientQuit,         // server to client
	PacketTypeServerQuit,              // server to client
	PacketTypeClientQuit,              // client to server
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