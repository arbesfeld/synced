//
//  MusicDownload.h
//  AirShare2
//
//  Created by mata on 3/24/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MusicItem.h"

@interface MusicDownload : NSObject

- (void)downloadFileWithMusicItem:(MusicItem *)musicItem andSessionID:(NSString *)sessionID progress:(void (^)(void))progress completion:(void (^)(void))completionBlock;

- (void)downloadBeatsWithMusicItem:(MusicItem *)musicItem andSessionID:(NSString *)sessionID completion:(void (^)(void))completionBlock;

@end
