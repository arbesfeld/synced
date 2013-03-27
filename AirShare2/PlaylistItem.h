//
//  PlaylistItem.h
//  AirShare2
//
//  Created by mata on 3/25/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

typedef enum
{
	PlaylistItemTypeSong,
    PlaylistItemTypeGame,
    PlaylistItemTypeMovie,
}
PlaylistItemType;

#import <Foundation/Foundation.h>

@interface PlaylistItem : NSObject {

@private
    int _upvoteCount, _downvoteCount;
}
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) NSString *ID;
@property (nonatomic, assign) PlaylistItemType playlistItemType;

- (id)initPlaylistItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andPlaylistItemType:(PlaylistItemType)playListItemType;

- (void)setUpvoteCount:(int)upvoteCount andDownvoteCount:(int)downvoteCount;
- (int)getUpvoteCount;
- (int)getDownvoteCount;
- (int)getScore;

- (void)upvote;
- (void)downvote;
@end
