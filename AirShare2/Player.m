
#import "Player.h"

@implementation Player

@synthesize name = _name;
@synthesize peerID = _peerID;
@synthesize receivedResponse = _receivedResponse;

- (void)dealloc
{
#ifdef DEBUG
	NSLog(@"dealloc %@", self);
#endif
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ peerID = %@, name = %@", [super description], self.peerID, self.name];
}

@end