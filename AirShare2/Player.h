
@interface Player : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *peerID;
@property (nonatomic, strong) NSMutableDictionary *hasMusicList;
@property (nonatomic, strong) NSMutableArray *packetSendTime;
@property (nonatomic, assign) NSTimeInterval timeOffset;
@property (nonatomic, assign) int syncPacketsReceived;
@end