//
//  PlayerView.h
//  AirShare2
//
//  Created by mata on 4/18/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

@interface PlayerView : MPMoviePlayerController

- (id)initWithContentURL:(NSURL *)url;

@end