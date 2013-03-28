//
//  LoadingItem.h
//  AirShare2
//
//  Created by mata on 3/28/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PlaylistItem.h"

@interface LoadingItem : PlaylistItem

@property(nonatomic, assign) double progress;

+ (id)loadingItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID;

@end
