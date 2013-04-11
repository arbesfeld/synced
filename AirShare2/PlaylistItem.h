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
    PlaylistItemTypeNone,
    PlaylistItemLoading, // show uploading animation
}
PlaylistItemType;

#import "AFNetworking.h" // for AFHTTPRequestOperation

#import <Foundation/Foundation.h>

@interface PlaylistItem : NSObject {

@private
    int _upvoteCount, _downvoteCount;
}
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) NSString *ID;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) PlaylistItemType playlistItemType;
@property (nonatomic, assign) double loadProgress;
@property (nonatomic, assign) double previousLoadProgress; // used for UI loading animation 
@property (nonatomic, assign) BOOL belongsToUser; // whether the user uploaded a given song
@property (nonatomic, assign) BOOL cancelled;
@property (nonatomic, assign) BOOL justVoted;

@property (nonatomic, assign) AFHTTPRequestOperation *uploadOperation;

- (id)initPlaylistItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andDate:(NSDate *)date andPlaylistItemType:(PlaylistItemType)playListItemType;

- (void)setUpvoteCount:(int)upvoteCount andDownvoteCount:(int)downvoteCount;
- (int)getUpvoteCount;
- (int)getDownvoteCount;
- (int)getScore;
- (NSComparisonResult)compare:(PlaylistItem *)other;

- (void)upvote:(int)amount;
- (void)downvote:(int)amount;

- (void)cancel;
- (BOOL)isCancelled;
@end
