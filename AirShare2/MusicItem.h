//
//  MusicItem.h
//  AirShare2
//
//  Created by mata on 3/25/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PlaylistItem.h"

@interface MusicItem : PlaylistItem

@property (nonatomic, retain) NSURL *songURL;
@property (nonatomic, assign) NSInteger beatPos;
@property (nonatomic, retain) NSMutableArray *beats;
@property (nonatomic, assign) BOOL partyMode;

+ (id)musicItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andDate:(NSDate *)date;

- (void)loadBeats;
- (void)nextBeat;

@end
