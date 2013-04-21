//
//  YoutubeItem.m
//  AirShare2
//
//  Created by mata on 4/21/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "YoutubeItem.h"

@implementation YoutubeItem

+ (id)youtubeItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andDate:(NSDate *)date andURL:(NSURL *)url 
{
	return [[[self class] alloc] initYoutubeItemWithName:name andSubtitle:subtitle andID:ID andDate:date andURL:url];
}

- (id)initYoutubeItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andDate:(NSDate *)date andURL:(NSURL *)url
{
	if ((self = [super initPlaylistItemWithName:name andSubtitle:subtitle andID:ID andDate:date andPlaylistItemType:PlaylistItemTypeYoutube]))
	{
        self.url = url;
	}
	return self;
}
@end
