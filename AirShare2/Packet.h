const size_t PACKET_HEADER_SIZE;
const size_t AUDIO_BUFFER_PACKET_HEADER_SIZE;
const size_t AUDIO_BUFFER_DATA_BYTE_SIZE_OFFSET;
const size_t AUDIO_BUFFER_NUMBER_OF_CHANNELS_OFFSET;
const size_t MAX_PACKET_SIZE;
const size_t PACKET_INFO_SIZE;
const size_t MAX_PACKET_DESCRIPTIONS_SIZE;
const size_t AUDIO_STREAM_PACK_DESC_SIZE;

//all the different types of messages we can send
typedef enum
{
	PacketTypeSignInRequest = 0x64,    // server to client
	PacketTypeSignInResponse,          // client to server
    
    PacketTypePlayerList,              // server to client
    
	PacketTypeServerReady,             // server to client
	PacketTypeClientReady,             // client to server
    
	PacketTypeDealCards,               // server to client
	PacketTypeClientDealtCards,        // client to server
    
    PacketTypeAudioBuffer,
    
	PacketTypeActivatePlayer,          // server to client
	PacketTypeClientTurnedCard,        // client to server
    
	PacketTypePlayerShouldSnap,        // client to server
	PacketTypePlayerCalledSnap,        // server to client
    
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