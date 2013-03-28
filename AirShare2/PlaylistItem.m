//
//  PlaylistItem.m
//  AirShare2
//
//  Created by mata on 3/25/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PlaylistItem.h"

@implementation PlaylistItem

@synthesize name = _name;
@synthesize subtitle = _subtitle;
@synthesize playlistItemType = _playlistItemType;

- (void)dealloc
{
#ifdef DEBUG
	NSLog(@"dealloc %@", self);
#endif
}

- (id)initPlaylistItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andPlaylistItemType:(PlaylistItemType)playListItemType
{
    if(self = [super init]) {
        self.name = name;
        self.subtitle = subtitle;
        self.ID = ID;
        self.playlistItemType = playListItemType;
        _upvoteCount = 0;
        _downvoteCount = 0;
    }
    return self;
}

- (void)setUpvoteCount:(int)upvoteCount andDownvoteCount:(int)downvoteCount {
    _upvoteCount = upvoteCount;
    _downvoteCount = downvoteCount;
}

- (int)getUpvoteCount {
    return _upvoteCount;
}
- (int)getDownvoteCount {
    return _downvoteCount;
}
- (int)getScore {
    return 1000 * (_upvoteCount - _downvoteCount) + abs(_upvoteCount) + abs(_downvoteCount);
}

- (void)upvote:(int)amount {
    _upvoteCount += amount;
}
- (void)downvote:(int)amount {
    _downvoteCount += amount;
}

- (BOOL)isEqual:(id)object {
    return self.ID == ((PlaylistItem *)object).ID;
}

- (NSComparisonResult)compare:(PlaylistItem *)other {
    return  [other getScore] - [self getScore];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ name = %@, subtitle = %@, ID = %@", [super description], self.name, self.subtitle, self.ID];
}

@end
