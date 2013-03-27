//
//  MusicDownload.h
//  AirShare2
//
//  Created by mata on 3/24/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MusicDownload : NSObject

-(void)downloadFileWithName:(NSString *)fileName completion:(void (^)(void))completionBlock;

@end
