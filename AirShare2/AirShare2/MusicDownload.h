//
//  MusicDownload.h
//  AirShare2
//
//  Created by mata on 3/24/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaItem.h"

@interface MusicDownload : NSObject

- (void)downloadFileWithMediaItem:(MediaItem *)mediaItem andSessionID:(NSString *)sessionID progress:(void (^)(void))progress completion:(void (^)(void))completion failure:(void (^)(void))failure;

- (void)downloadBeatsWithMediaItem:(MediaItem *)mediaItem andSessionID:(NSString *)sessionID completion:(void (^)(void))completionBlock;

@end
