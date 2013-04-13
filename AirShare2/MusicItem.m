//
//  MusicItem.m
//  AirShare2
//
//  Created by mata on 3/25/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "MusicItem.h"
#import <AVFoundation/AVFoundation.h>

@implementation MusicItem

@synthesize songURL = _songURL;
@synthesize beatPos = _beatPos;
@synthesize partyMode = _partyMode;
@synthesize beats = _beats;

+ (id)musicItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andDate:(NSDate *)date;
{
	return [[[self class] alloc] initMusicItemWithName:name andSubtitle:subtitle andID:ID andDate:date];
}

- (id)initMusicItemWithName:(NSString *)name andSubtitle:(NSString *)subtitle andID:(NSString *)ID andDate:(NSDate *)date
{
	if ((self = [super initPlaylistItemWithName:name andSubtitle:subtitle andID:ID andDate:date andPlaylistItemType:PlaylistItemTypeSong]))
	{
        NSString *tempPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *fileName = [NSString stringWithFormat:@"%@.m4a", ID];
        NSString *songPath = [tempPath stringByAppendingPathComponent:fileName];
		self.songURL = [[NSURL alloc] initWithString:songPath];
        self.beats = [[NSMutableArray alloc] init];
        self.beatPos = -1;
        self.partyMode = NO;
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@, url = %@", [super description],[self.songURL absoluteString]];
}

- (void)loadBeats
{
    // read from ID-beats.txt
    // load into beats
    // update beatPos = 0;
    
    NSString *saveName = [NSString stringWithFormat:@"%@-beats.txt", self.ID];
    saveName = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:saveName];
    NSString* fileContents = [NSString stringWithContentsOfFile:saveName encoding:NSUTF8StringEncoding error:nil];
    //NSLog(@"got filepath: %@", saveName);
    //NSLog(@"got filecontents: %@", fileContents);
    
    NSArray* allLinedStrings = [fileContents componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
    
    for (int i = 0; i < [allLinedStrings count]; i++) {
        NSString* cur = [allLinedStrings objectAtIndex:i];
    
        NSArray* singleStrs = [cur componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@" "]];
        if ([singleStrs count] > 1 && [[singleStrs objectAtIndex:1] hasPrefix:@"1"]) {
            // add it!
            NSString *beat = [[singleStrs objectAtIndex:0] substringToIndex:[[singleStrs objectAtIndex:0] length] - 1];
            //NSLog(@"Beat: %@", beat);
            [self.beats addObject:[NSNumber numberWithDouble:[beat doubleValue]]];
        }
    }
    NSLog(@"BEATS LOADED! There are %d.", [self.beats count]);
    
    self.beatPos = 0;
}

// advance beat pointer and perform action
- (void)nextBeat
{
    self.beatPos++;
    NSLog(@"BEAT!!");
    
    if (self.partyMode == YES) {
        Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
        if (captureDeviceClass != nil) {
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            if ([device hasTorch] && [device hasFlash]){
                [device lockForConfiguration:nil];
                
                [device setTorchModeOnWithLevel:0.1 error:NULL];
            
                // turn on
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
            
                // wait
                [self performSelector:@selector(turnOff:) withObject:device afterDelay:0.1];
            }
        }
    }
}

- (void)turnOff:(AVCaptureDevice *)device
{
    // turn off
    [device setTorchMode:AVCaptureTorchModeOff];
    [device setFlashMode:AVCaptureFlashModeOff];
    
    [device unlockForConfiguration];
}

@end
