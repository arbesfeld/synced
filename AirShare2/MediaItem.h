//
//  MediaItem.h
//  AirShare2
//
//  Created by mata on 3/25/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PlaylistItem.h"


@interface MediaItem : PlaylistItem

@property (nonatomic, retain) NSURL *url, *originalURL;
@property (nonatomic, assign) NSInteger beatPos;
@property (nonatomic, retain) NSMutableArray *beats;
@property (nonatomic, assign) BOOL beatsLoaded;
@property (nonatomic, strong) UIViewController *controller;

+ (id)mediaItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andDate:(NSDate *)date andURL:(NSURL *)url uploadedByUser:(BOOL)uploadedByUser andPlayListItemType:(PlaylistItemType)playlistItemType;

- (void)loadBeats;
- (void)skipBeat;
- (void)nextBeat;

@end
