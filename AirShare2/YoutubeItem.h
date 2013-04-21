//
//  YoutubeItem.h
//  AirShare2
//
//  Created by mata on 4/21/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PlaylistItem.h"

@interface YoutubeItem : PlaylistItem

+ (id)youtubeItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andDate:(NSDate *)date andURL:(NSURL *)url;

@property (nonatomic, strong) NSURL *url;

@end
