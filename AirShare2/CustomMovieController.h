//
//  CustomMovieController.h
//  AirShare2
//
//  Created by mata on 4/17/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import "PlayerView.h"
#import "MediaItem.h"

@class CustomMovieController;

@protocol CustomMovieControllerDelegate <NSObject>

- (void)skipButtonPressed;
- (void)sendSyncPacketsForItem:(MediaItem *)mediaItem;

@end

@interface CustomMovieController : UIViewController {
    NSTimer *_fadeOutTimer;
}
@property (nonatomic, weak) id <CustomMovieControllerDelegate> delegate;
@property (nonatomic, strong) PlayerView *moviePlayer;
@property (nonatomic, strong) UIButton *skipButton, *fadeButton;
@property (nonatomic, strong) UILabel *skipLabel;
@property (nonatomic, strong) UIImage *skipImage;
@property (nonatomic, strong) UIView *controlBackground;
@property (nonatomic, strong) MediaItem *mediaItem;
@property (nonatomic, strong) MPVolumeView *volumeView;

- (id)initWithMediaItem:(MediaItem *)mediaItem;
- (void)setSkipCount:(int)skipCount total:(int)total;
- (void)stop;
@end
