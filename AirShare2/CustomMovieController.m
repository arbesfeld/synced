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

- (id)initWithMediaItem:(MediaItem *)mediaItem
{
    self = [super init];
    
    if(self) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
        
        CGRect frame = [UIScreen mainScreen].applicationFrame;
        _mediaItem = mediaItem;
        _moviePlayer = [[PlayerView alloc] initWithMediaItem:mediaItem];
        [self.view addSubview:_moviePlayer];
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
            if (orientation == UIInterfaceOrientationLandscapeLeft ||
                orientation == UIInterfaceOrientationLandscapeRight) {
                float height = frame.size.height;
                frame.size.height = frame.size.width;
                frame.size.width = height;
            }
            _skipLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - 130, frame.size.height - 74, 50, 50)];
            _skipLabel.font = [UIFont fontWithName:@"Century Gothic" size:24.0f];
            _skipButton = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width - 80, frame.size.height - 70, 50, 45.59)];
            _controlBackground = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width - 153, frame.size.height - 85, 137, 72)];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(didRotate:)
                                                         name:UIApplicationDidChangeStatusBarOrientationNotification
                                                       object:nil];
        } else {
            _skipLabel = [[UILabel alloc] initWithFrame:CGRectMake(17, frame.size.height - 95, 34, 31)];
            [_skipLabel setTransform:CGAffineTransformMakeRotation(M_PI / 2)];
            _skipLabel.font = [UIFont fontWithName:@"Century Gothic" size:20.0f];
            _skipButton = [[UIButton alloc] initWithFrame:CGRectMake(13, frame.size.height - 55, 40, 37)];
            [_skipButton setTransform:CGAffineTransformMakeRotation(M_PI / 2)];
            _controlBackground = [[UIView alloc] initWithFrame:CGRectMake(3, frame.size.height - 117, 61, 111)];
        }
        
        _skipLabel.textColor = [UIColor grayColor];
        _skipLabel.backgroundColor = [UIColor clearColor];
        [_skipLabel setAlpha:0.0];
        [self setSkipCount:0 total:0];
        
        _skipImage = [UIImage imageNamed:@"skip-01.png"];
        [_skipButton setImage:_skipImage forState:UIControlStateNormal];
        [_skipButton addTarget:self action:@selector(skipButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_skipButton setAlpha:0.0];
        _skipButton.enabled = NO;
        
        _controlBackground.layer.cornerRadius = 5;
        _controlBackground.layer.masksToBounds = YES;
        _controlBackground.layer.borderColor = [UIColor grayColor].CGColor;
        _controlBackground.backgroundColor = [UIColor blackColor];
        _controlBackground.layer.borderWidth = 3.0f;
        [_controlBackground setAlpha:0.0];
        
        _fadeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _fadeButton.frame = frame;
        [_fadeButton addTarget:self action:@selector(fadeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:_skipLabel];
        [self.view addSubview:_skipButton];
        [self.view addSubview:_controlBackground];
        [self.view addSubview:_fadeButton];
        [self.view bringSubviewToFront:_controlBackground];
        [self.view bringSubviewToFront:_skipLabel];
        [self.view bringSubviewToFront:_fadeButton];
        [self.view bringSubviewToFront:_skipButton];
    }
    return self;
}

- (void)didRotate:(NSNotification *)notification {
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationLandscapeLeft ||
        orientation == UIInterfaceOrientationLandscapeRight) {
        float height = frame.size.height;
        frame.size.height = frame.size.width;
        frame.size.width = height;
    }
    self.view.frame = frame;
    _skipLabel.frame = CGRectMake(frame.size.width - 130, frame.size.height - 74, 50, 50);
    _skipButton.frame = CGRectMake(frame.size.width - 80, frame.size.height - 70, 50, 45.59);
    _controlBackground.frame = CGRectMake(frame.size.width - 150, frame.size.height - 85, 137, 72);
    _fadeButton.frame = self.view.frame;
}

- (void)skipButtonPressed:(id)sender
{
    [self.delegate skipButtonPressed];
}

- (void)fadeButtonPressed:(id)sender
{
    NSLog(@"Fade button pressed");
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [_skipLabel setAlpha:1.0];
    [_skipButton setAlpha:1.0];
    [_controlBackground setAlpha:0.75];
    [UIView commitAnimations];
    if(_fadeOutTimer) {
        [_fadeOutTimer invalidate];
        _fadeOutTimer = nil;
    }
    _skipButton.enabled = YES;
    _fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(fadeOut:) userInfo:nil repeats:NO];
}

- (void)fadeOut:(NSTimer *)timer
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [_skipLabel setAlpha:0.0];
    [_skipButton setAlpha:0.0];
    [_controlBackground setAlpha:0.0];
    [UIView commitAnimations];
    _skipButton.enabled = NO;
}

- (void)setSkipCount:(int)skipCount total:(int)total
{
    _skipLabel.text = [NSString stringWithFormat:@"%d/%d", skipCount, total];
}

- (void)play
{
    [_moviePlayer play];
    
    [self.delegate sendSyncPacketsForItem:_mediaItem];
}
- (void)stop
{
    [_moviePlayer stop];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name: UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name: UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        NSLog(@"applicationDidEnterBackground:CustomMovieController");
        
        [self performSelector:@selector(play) withObject:nil afterDelay:0.001];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self.delegate sendSyncPacketsForItem:_mediaItem];
}
@end
