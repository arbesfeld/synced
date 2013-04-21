//
//  MediaItem.h
//  AirShare2
//
//  Created by mata on 3/25/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PlaylistItem.h"

@interface MediaItem : PlaylistItem

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, assign) NSInteger beatPos;
@property (nonatomic, retain) NSMutableArray *beats;
@property (nonatomic, assign) BOOL partyMode;

+ (id)mediaItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andDate:(NSDate *)date andURL:(NSURL *)url andPlayListItemType:(PlaylistItemType)playlistItemType;

- (void)loadBeats;
- (void)nextBeat;
- (void)togglePartyMode;

@end
