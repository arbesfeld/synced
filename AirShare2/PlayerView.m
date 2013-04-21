//
//  PlayerView.m
//  AirShare2
//
//  Created by mata on 4/18/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "PlayerView.h"

@implementation PlayerView

- (void)dealloc
{
    NSLog(@"dealloc: %@", [self description]);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithMediaItem:(MediaItem *)mediaItem
{
    self = [super init];
    if(self) {
        self.mediaItem = mediaItem;
        
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:NO];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
        CGRect frame = [UIScreen mainScreen].applicationFrame;
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            // Device is iPad
            //[self setFullscreen:YES animated:YES];
            //self.view.frame = [self.view superview].frame;
            UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
            
            if(orientation == 0 || orientation == UIInterfaceOrientationPortrait) {
                self.frame = frame;
            } else if (orientation == UIInterfaceOrientationLandscapeLeft ||
                       orientation == UIInterfaceOrientationLandscapeRight) {
                float height = frame.size.height;
                frame.size.height = frame.size.width;
                frame.size.width = height;
            }
            
            self.frame = frame;
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(didRotate:)
                                                         name:UIApplicationDidChangeStatusBarOrientationNotification
                                                       object:nil];
        } else {
            float width = frame.size.width;
            float height = frame.size.height;
            self.bounds = CGRectMake(0, 0, height*2, width*2);
            self.center = CGPointMake(width + 10, height - 80);
            self.transform = CGAffineTransformMakeRotation(M_PI / 2);
            //NSLog(@"width = %f, height = %f", width, height);
        }
        _playerItem = [AVPlayerItem playerItemWithURL:mediaItem.url];
        _player = [AVPlayer playerWithPlayerItem:_playerItem];
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        
        _playerLayer.frame = self.frame;
        [self.layer addSublayer:_playerLayer];
        
    }
    return self;
}

- (void)play {
    [_player play];
}
- (void)stop
{
    [_player pause];
}
- (void)didRotate:(NSNotification *)notification {
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if(orientation == 0 || orientation == UIInterfaceOrientationPortrait) {
        self.frame = frame;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft ||
               orientation == UIInterfaceOrientationLandscapeRight) {
        float height = frame.size.height;
        frame.size.height = frame.size.width;
        frame.size.width = height;
    }
    self.frame = frame;
}

@end