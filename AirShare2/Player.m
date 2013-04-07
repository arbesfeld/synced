
#import "Player.h"

@implementation Player

@synthesize name = _name;
@synthesize peerID = _peerID;
@synthesize hasMusicList = _hasMusicList;
@synthesize packetSendTime = _packetSendTime;
@synthesize timeOffset = _timeOffset;
@synthesize syncPacketsReceived = _syncPacketsReceived;

- (void)dealloc
{
#ifdef DEBUG
	//NSLog(@"dealloc %@", self);
#endif
}
- (id)init
{
	if ((self = [super init]))
	{
        _hasMusicList = [[NSMutableDictionary alloc] initWithCapacity:10];
        _packetSendTime = [[NSMutableArray alloc] initWithCapacity:50];
        _timeOffset = 0.0;
        _syncPacketsReceived = 0;
	}
	return self;
}
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ peerID = %@, name = %@", [super description], self.peerID, self.name];
}

@end