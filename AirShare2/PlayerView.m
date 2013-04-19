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

- (id)initWithContentURL:(NSURL *)url
{
    self = [super initWithContentURL:url];
    
    if(self) {
        //self.shouldAutoplay = NO;
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:NO];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
        CGRect frame = [UIScreen mainScreen].applicationFrame;
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            // Device is iPad
            [self setFullscreen:YES animated:YES];
            //self.view.frame = [self.view superview].frame;
            UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
            
            if(orientation == 0 || orientation == UIInterfaceOrientationPortrait) {
                self.view.frame = frame;
            } else if (orientation == UIInterfaceOrientationLandscapeLeft ||
                       orientation == UIInterfaceOrientationLandscapeRight) {
                float height = frame.size.height;
                frame.size.height = frame.size.width;
                frame.size.width = height;
            }
            
            self.view.frame = frame;
            id center = [NSNotificationCenter defaultCenter];
            [center addObserver:self
                       selector:@selector(didRotate:)
                           name:UIApplicationDidChangeStatusBarOrientationNotification
                         object:nil];
        } else {
            float width = UIScreen.mainScreen.bounds.size.width;
            float height = UIScreen.mainScreen.bounds.size.height;
            [self.view setBounds:CGRectMake(0, 0, height, width)];
            [self.view setCenter:CGPointMake(width / 2, height / 2)];
            [self.view setTransform:CGAffineTransformMakeRotation(M_PI / 2)];
            //NSLog(@"width = %f, height = %f", width, height);
        }
        self.controlStyle = MPMovieControlStyleNone;
    }
    return self;
}
- (void)play {
    [super play];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}
- (void)didRotate:(NSNotification *)notification {
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if(orientation == 0 || orientation == UIInterfaceOrientationPortrait) {
        self.view.frame = frame;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft ||
               orientation == UIInterfaceOrientationLandscapeRight) {
        float height = frame.size.height;
        frame.size.height = frame.size.width;
        frame.size.width = height;
    }
    self.view.frame = frame;
}
- (void)stop
{
    [super stop];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

@end