//
//  MusicItem.h
//  AirShare2
//
//  Created by mata on 3/25/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PlaylistItem.h"

@interface MusicItem : PlaylistItem

@property(nonatomic, retain) NSURL *songURL;

+ (id)musicItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID;

@end
