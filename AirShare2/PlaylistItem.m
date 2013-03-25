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

-(id)initPlaylistItemWithName:(NSString *)name subtitle:(NSString *)subtitle playlistItemType:(PlaylistItemType)playListItemType
{
    if(self = [super init]) {
        self.name = name;
        self.subtitle = subtitle;
        self.playlistItemType = playListItemType;
        _upvoteCount = 0;
        _downvoteCount = 0;
    }
    return self;
}

-(int)getUpvoteCount {
    return _upvoteCount;
}
-(int)getDownvoteCount {
    return _downvoteCount;
}
-(int)getScore {
    return 100 * (_upvoteCount - _downvoteCount) + abs(_upvoteCount + _downvoteCount);
}

-(void)upvote {
    _upvoteCount++;
}
-(void)downvote {
    _downvoteCount++;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ name = %@, subtitle = %@", [super description], self.name, self.subtitle];
}

@end
