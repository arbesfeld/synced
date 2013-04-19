//
//  CustomMovieController.h
//  AirShare2
//
//  Created by mata on 4/17/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "PlayerView.h"

@class CustomMovieController;

@protocol CustomMovieControllerDelegate <NSObject>

- (void)skipButtonPressed;

@end

@interface CustomMovieController : UIViewController

@property (nonatomic, weak) id <CustomMovieControllerDelegate> delegate;
@property (nonatomic, strong) PlayerView *moviePlayer;
@property (nonatomic, strong) UIButton *skipButton;
@property (nonatomic, strong) UIImage *skipImage;
- (id)initWithContentURL:(NSURL *)url;
- (void)stop;
@end
