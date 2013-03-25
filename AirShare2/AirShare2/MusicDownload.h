//
//  MusicDownload.h
//  AirShare2
//
//  Created by mata on 3/24/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class Game;

@interface MusicDownload : NSObject <AVAudioPlayerDelegate>
{
    Game *_game;
    AVAudioPlayer *_audioPlayer;
}

-(id)initWithGame:(Game *)game;

-(void)downloadFileWithName:(NSString *)fileName andArtistName:(NSString *)artistName;

@end
