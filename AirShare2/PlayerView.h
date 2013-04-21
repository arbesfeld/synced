//
//  PlayerView.h
//  AirShare2
//
//  Created by mata on 4/18/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#import "MediaItem.h"
#import "LBYouTubeExtractor.h"
@interface PlayerView : UIView 

@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) MediaItem *mediaItem;

- (id)initWithMediaItem:(MediaItem *)mediaItem;
- (void)play;
- (void)stop;
@end