//
//  MediaItem.m
//  AirShare2
//
//  Created by mata on 3/25/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "MediaItem.h"
#import <AVFoundation/AVFoundation.h>

@implementation MediaItem

@synthesize beatPos = _beatPos;
@synthesize beats = _beats;

@synthesize data = _data;

+ (id)mediaItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andDate:(NSDate *)date andURL:(NSURL *)url uploadedByUser:(BOOL)uploadedByUser andPlayListItemType:(PlaylistItemType)playlistItemType
{
	return [[[self class] alloc] initMediaItemWithName:name andSubtitle:subtitle andID:ID andDate:date andURL:url uploadedByUser:uploadedByUser andPlayListItemType:playlistItemType];
}

- (id)initMediaItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andDate:(NSDate *)date andURL:(NSURL *)url uploadedByUser:(BOOL)uploadedByUser andPlayListItemType:(PlaylistItemType)playlistItemType
{
	if ((self = [super initPlaylistItemWithName:name andSubtitle:subtitle andID:ID andDate:date andPlaylistItemType:playlistItemType]))
	{
        self.uploadedByUser = uploadedByUser;
        if((playlistItemType == PlaylistItemTypeMovie && !uploadedByUser) ||
           playlistItemType == PlaylistItemTypeSong) {
            NSString *tempPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *fileName = [NSString stringWithFormat:@"%@.m4a", ID];
            NSString *songPath = [tempPath stringByAppendingPathComponent:fileName];
            self.url = [[NSURL alloc] initWithString:songPath];
        } else {
            self.url = url;
        }
        self.originalURL = url;
        self.beats = [[NSMutableArray alloc] init];
        self.beatPos = -1;
        self.beatsLoaded = NO;
        
        self.data = [[NSMutableDictionary alloc] init];
        self.dataStart = NO;
        self.dataDone = NO;
	}
	return self;
}

- (NSString *)descriptions
{
	return [NSString stringWithFormat:@"%@", [super description]];
}
- (void)loadBeats
{
    // read from ID-beats.txt
    // load into beats
    // update beatPos = 0;
    
    NSString *saveName = [NSString stringWithFormat:@"%@-beats.txt", self.ID];
    saveName = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:saveName];
    NSString* fileContents = [NSString stringWithContentsOfFile:saveName encoding:NSUTF8StringEncoding error:nil];
    //NSLog(@"got filepath: %@", saveName);
    //NSLog(@"got filecontents: %@", fileContents);
    
    NSArray* allLinedStrings = [fileContents componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
    
    for (int i = 0; i < [allLinedStrings count]; i++) {
        NSString* cur = [allLinedStrings objectAtIndex:i];
        
        NSArray* singleStrs = [cur componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@" "]];
        singleStrs = [singleStrs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        if ([singleStrs count] > 1 && [[singleStrs objectAtIndex:1] length] > 0) {
            // add it!
            NSString *beat = [[singleStrs objectAtIndex:0] substringToIndex:[[singleStrs objectAtIndex:0] length] - 1];
            [self.beats addObject:[NSNumber numberWithDouble:[beat doubleValue]]];
        }
    }
    NSLog(@"BEATS LOADED! There are %d.", [self.beats count]);
    self.beatsLoaded = YES;
    self.beatPos = 0;
}

- (void)skipBeat
{
    self.beatPos++;
}

- (void)addData:(NSData *)value atIndex:(int)index withTotalLength:(int)length
{
    self.dataStart = YES;
    
    [self.data setObject:value forKey:[NSNumber numberWithInt:index]];
    
    // check if we should finalize data
    if ([self.data count] == length) {
        // download data to file
        NSString *tempPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *fileName = [NSString stringWithFormat:@"%@.m4a", self.ID];
        NSString *songPath = [tempPath stringByAppendingPathComponent:fileName];
        
        NSMutableData *allData = [[NSMutableData alloc] init];
        for (int i = 0; i < length; i++) {
            [allData appendData:(NSData *)[self.data objectForKey:[NSNumber numberWithInt:i]]];
        }
        
        [allData writeToFile:songPath atomically:YES];
        
        NSLog(@"song downloaded to %@", songPath);
        
        self.dataDone = YES;
    }
}


@end
