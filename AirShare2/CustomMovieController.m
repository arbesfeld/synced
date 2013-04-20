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
}
- (id)initWithContentURL:(NSURL *)url
{
    self = [super init];
    
    if(self) {
        CGRect frame = [UIScreen mainScreen].applicationFrame;
        self.view.frame = frame;
        
        _moviePlayer = [[PlayerView alloc] initWithContentURL:url];
        [self.view addSubview:_moviePlayer];
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
            if(orientation == 0 || orientation == UIInterfaceOrientationPortrait) {
            } else if (orientation == UIInterfaceOrientationLandscapeLeft ||
                       orientation == UIInterfaceOrientationLandscapeRight) {
                float height = frame.size.height;
                frame.size.height = frame.size.width;
                frame.size.width = height;
            }
            _skipButton = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width - 80, frame.size.height - 50, 50, 50)];
            _skipImage = [UIImage imageNamed:@"skip-01.png"];
            
            id center = [NSNotificationCenter defaultCenter];
            [center addObserver:self
                       selector:@selector(didRotate:)
                           name:UIApplicationDidChangeStatusBarOrientationNotification
                         object:nil];
        } else {
            _skipButton = [[UIButton alloc] initWithFrame:CGRectMake(15, frame.size.height - 35, 34, 31)];
            _skipImage = [UIImage imageNamed:@"skip-01-rotated.png"];
        }
        
        [_skipButton setNeedsDisplay];
        
        [_skipButton addTarget:self action:@selector(skipButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [_skipButton setImage:_skipImage forState:UIControlStateNormal];
        [self.view addSubview:_skipButton];
        [self.view bringSubviewToFront:_skipButton];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name: UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name: UIApplicationDidBecomeActiveNotification object:nil];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self performSelector:@selector(playWithDelay) withObject:nil afterDelay:0.15];
}
- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    CMTime npt = CMTimeMakeWithSeconds(CMTimeGetSeconds([_moviePlayer.player currentTime]) + 0.15, 600);
    [_moviePlayer.player seekToTime:npt toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}
- (void)playWithDelay
{
    [_moviePlayer play];
    CMTime npt = CMTimeMakeWithSeconds(CMTimeGetSeconds([_moviePlayer.player currentTime]) + 0.1, 600);
    [_moviePlayer.player seekToTime:npt toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
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
    _skipButton.frame = CGRectMake(frame.size.width - 80, frame.size.height - 50, 34, 31);
}
- (void)skipButtonPressed:(id)sender
{
    [self.delegate skipButtonPressed];
}

- (void)stop
{
    [_moviePlayer stop];
}
@end
