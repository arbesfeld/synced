//
//  CustomMovieController.m
//  AirShare2
//
//  Created by mata on 4/17/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "CustomMovieController.h"

@implementation CustomMovieController

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
        UIButton *skipButton;
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            // Device is iPad
            //[self setFullscreen:YES animated:YES];
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
            skipButton = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width - 50, frame.size.height - 70, 34, 31)];
            
            id center = [NSNotificationCenter defaultCenter];
            [center addObserver:self
                       selector:@selector(didRotate:)
                           name:UIApplicationDidChangeStatusBarOrientationNotification
                         object:nil];
        } else {
            float width = UIScreen.mainScreen.bounds.size.width;
            float height = UIScreen.mainScreen.bounds.size.height;
            skipButton = [[UIButton alloc] initWithFrame:CGRectMake(480, 280, 50, 45.59f)];
            skipButton.clipsToBounds = YES;
            [self.view setBounds:CGRectMake(20, 0, height, width + 20)];
            [self.view setCenter:CGPointMake(width / 2, height / 2)];
            [self.view setTransform:CGAffineTransformMakeRotation(M_PI / 2)];
            NSLog(@"width = %f, height = %f", width, height);
        }
        self.controlStyle = MPMovieControlStyleNone;
        
        UIView *controlsView = [[UIView alloc] initWithFrame:self.view.frame];
        [skipButton addTarget:self action:@selector(skipButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [skipButton setNeedsDisplay];
        UIImage *skipImage = [UIImage imageNamed:@"skip-01.png"];
        [skipButton setImage:skipImage forState:UIControlStateNormal];
        [controlsView addSubview:skipButton];
        [self.view addSubview:controlsView];
        [self.view bringSubviewToFront:controlsView];
    }
    return self;
}

- (void)skipButtonPressed:(id)sender
{
    [self.delegate skipButtonPressed];
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
