#import "Packet.h"
#import "NSData+AirShareAdditions.h"
#import "PacketSignInResponse.h"
#import "PacketPlayerList.h"
#import "PacketOtherClientQuit.h"
#import "PacketMusic.h"
#import "PacketPlayMusicNow.h"
#import "PacketMusicResponse.h"

const size_t PACKET_HEADER_SIZE = 10;

@implementation Packet

@synthesize packetType = _packetType;
@synthesize packetNumber = _packetNumber;

+ (id)packetWithType:(PacketType)packetType
{
	return [[[self class] alloc] initWithType:packetType];
}

+ (id)packetWithData:(NSData *)data
{
	if ([data length] < PACKET_HEADER_SIZE)
	{
		NSLog(@"Error: Packet too small");
		return nil;
	}
    
	if ([data rw_int32AtOffset:0] != 'AIRS')
	{
		NSLog(@"Error: Packet has invalid header");
		return nil;
	}
    
	int packetNumber = [data rw_int32AtOffset:4];
	PacketType packetType = [data rw_int16AtOffset:8];
    
	Packet *packet;
    
	switch (packetType)
	{
		case PacketTypeSignInRequest:
        case PacketTypeServerQuit:
        case PacketTypeClientQuit:
        case PacketTypeMusicReady:
			packet = [Packet packetWithType:packetType];
			break;
            
		case PacketTypeSignInResponse:
			packet = [PacketSignInResponse packetWithData:data];
			break;
            
        case PacketTypePlayerList:
			packet = [PacketPlayerList packetWithData:data];
			break;
            
        case PacketTypeOtherClientQuit:
			packet = [PacketOtherClientQuit packetWithData:data];
			break;
        
        case PacketTypeMusic:
            packet = [PacketMusic packetWithData:data];
            break;
            
        case PacketTypeMusicResponse:
            packet = [PacketMusicResponse packetWithData:data];
            break;
            
        case PacketTypePlayMusicNow:
            packet = [PacketPlayMusicNow packetWithData:data];
            break;
            
		default:
			NSLog(@"Error: Packet has invalid type");
			return nil;
	}
    packet.packetNumber = packetNumber;
	return packet;
}

- (id)initWithType:(PacketType)packetType
{
	if ((self = [super init]))
	{
		self.packetNumber = -1;
		self.packetType = packetType;
	}
	return self;
}

- (NSData *)data
{
	NSMutableData *data = [[NSMutableData alloc] initWithCapacity:100];
    
	[data rw_appendInt32:'AIRS'];
	[data rw_appendInt32:self.packetNumber];
	[data rw_appendInt16:self.packetType];
    
	[self addPayloadToData:data];
	return data;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ number=%d, type=%d", [super description], self.packetNumber, self.packetType];
}

- (void)addPayloadToData:(NSMutableData *)data
{
	// base class does nothing
}

@end