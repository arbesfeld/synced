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

+ (id)musicItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID;
{
	return [[[self class] alloc] initMusicItemWithName:name andSubtitle:subtitle andID:ID];
}

- (id)initMusicItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID;
{
	if ((self = [super initPlaylistItemWithName:name andSubtitle:subtitle andID:ID andPlaylistItemType:PlaylistItemTypeSong]))
	{
        NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
        
        NSString *songName = [[name componentsSeparatedByCharactersInSet:
                               [[NSCharacterSet alphanumericCharacterSet] invertedSet]]
                              componentsJoinedByString:@""];
        NSString *fileName = [NSString stringWithFormat:@"%@.m4a", songName];
        NSString *songPath = [documentsDirectoryPath stringByAppendingPathComponent:fileName];
		self.songURL = [[NSURL alloc] initWithString:songPath];
	}
	return self;
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"%@, url = %@", [super description],[self.songURL absoluteString]];
}
@end
