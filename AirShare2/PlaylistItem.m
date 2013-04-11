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
@synthesize loadProgress = _loadProgress;
@synthesize belongsToUser = _belongsToUser;

- (void)dealloc
{
#ifdef DEBUG
	//NSLog(@"dealloc %@", self);
#endif
}

- (id)initPlaylistItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andDate:(NSDate *)date andPlaylistItemType:(PlaylistItemType)playListItemType
{
    if(self = [super init]) {
        self.name = name;
        self.subtitle = subtitle;
        self.ID = ID;
        self.playlistItemType = playListItemType;
        self.date = date;
        _upvoteCount = 0;
        _downvoteCount = 0;
        _loadProgress = 0.0;
        _previousLoadProgress = 0.0;
        _cancelled = NO;
        _uploadOperation = nil;
        _belongsToUser = NO;
        _justVoted = NO;
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
//    if(_loadProgress != 1.0) {
//        return -1000 +_upvoteCount - _downvoteCount;
//    } else {
        return _upvoteCount - _downvoteCount;
//    }
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
    if([other getScore] - [self getScore] == 0) {
        return [self.date timeIntervalSinceDate:other.date];
    } else {
        return [other getScore] - [self getScore];
    }
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ name = %@, subtitle = %@, ID = %@, progress = %f", [super description], self.name, self.subtitle, self.ID, self.loadProgress];
}

- (void)cancel
{
    if (_uploadOperation != nil) {
        [_uploadOperation cancel];
    }
    _cancelled = YES;
}

- (BOOL)isCancelled
{
    return _cancelled == YES;
}

@end
