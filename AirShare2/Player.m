
#import "Player.h"

@implementation Player

@synthesize name = _name;
@synthesize peerID = _peerID;
@synthesize receivedResponse = _receivedResponse;
@synthesize lastPacketNumberReceived = _lastPacketNumberReceived;

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
		_lastPacketNumberReceived = -1;
	}
	return self;
}
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ peerID = %@, name = %@", [super description], self.peerID, self.name];
}

@end