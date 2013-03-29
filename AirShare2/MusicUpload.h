//
//  MusicUpload.h
//  AirShare2
//
//  Created by mata on 3/24/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MusicItem.h"

@interface MusicUpload : NSObject

- (void)convertAndUpload:(MusicItem *)musicItem withAssetURL:(NSURL *)assetURL completion:(void (^)())completionBlock;

@end
