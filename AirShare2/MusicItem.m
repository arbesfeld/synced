//
//  MusicItem.m
//  AirShare2
//
//  Created by mata on 3/25/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "MusicItem.h"

@implementation MusicItem

@synthesize songURL = _songURL;

+(id)musicItemWithName:(NSString *)name subtitle:(NSString *)subtitle andURL:(NSURL *)songURL;
{
	return [[[self class] alloc] initMusicItemWithName:name subtitle:subtitle andURL:songURL];
}

- (id)initMusicItemWithName:(NSString *)name subtitle:(NSString *)subtitle andURL:(NSURL *)songURL
{
	if ((self = [super initPlaylistItemWithName:name subtitle:subtitle playlistItemType:PlaylistItemGame]))
	{
		self.songURL = songURL;
	}
	return self;
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ name = %@, subtitle = %@, url = %@", [super description], self.name, self.subtitle, [self.songURL absoluteString]];
}
@end
