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

+ (id)musicItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andFileSize:(int)fileSize;
{
	return [[[self class] alloc] initMusicItemWithName:name andSubtitle:subtitle andID:ID andFileSize:fileSize];
}

- (id)initMusicItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andFileSize:(int)fileSize;
{
	if ((self = [super initPlaylistItemWithName:name andSubtitle:subtitle andID:ID andPlaylistItemType:PlaylistItemTypeSong]))
	{
        NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
        NSString *fileName = [NSString stringWithFormat:@"%@.m4a", ID];
        NSString *songPath = [documentsDirectoryPath stringByAppendingPathComponent:fileName];
		self.songURL = [[NSURL alloc] initWithString:songPath];
        self.fileSize = fileSize;
	}
	return self;
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"%@, url = %@, filesize = %d", [super description],[self.songURL absoluteString], self.fileSize];
}
@end
