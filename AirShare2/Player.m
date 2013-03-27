
#import "Player.h"

@implementation Player

@synthesize name = _name;
@synthesize peerID = _peerID;
@synthesize hasMusicList = _hasMusicList;

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
        _hasMusicList = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
	return self;
}
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ peerID = %@, name = %@", [super description], self.peerID, self.name];
}

@end