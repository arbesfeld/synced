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
#import "MediaItem.h"
#import "PacketMusicData.h"

@interface MusicUpload : NSObject

- (void)convertAndUpload:(MediaItem *)mediaItem withAssetURL:(NSURL *)assetURL andSessionID:(NSString *)sessionID progress:(void (^)(PacketMusicData *))progress completion:(void (^)())completion failure:(void (^)())failure;

@end
