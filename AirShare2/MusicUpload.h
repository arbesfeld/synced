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

@class Game;

@interface MusicUpload : NSObject {
    Game *_game;
    NSString *_exportPath;
}

-(id)initWithGame:(Game *)game;

-(void)convertAndUpload:(MPMediaItem *)mediaItem;

@end
