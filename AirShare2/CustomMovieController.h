//
//  CustomMovieController.h
//  AirShare2
//
//  Created by mata on 4/17/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

@class CustomMovieController;

@protocol CustomMovieControllerDelegate <NSObject>

- (void)skipButtonPressed;

@end

@interface CustomMovieController : MPMoviePlayerController

@property (nonatomic, weak) id <CustomMovieControllerDelegate> delegate;

- (id)initWithContentURL:(NSURL *)url;

@end
