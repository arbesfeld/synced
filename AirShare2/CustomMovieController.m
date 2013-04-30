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
    
    [self resignFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self becomeFirstResponder];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name: UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name: UIApplicationDidBecomeActiveNotification object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}
- (id)initWithMediaItem:(MediaItem *)mediaItem
{
    self = [super init];
    
    if(self) {
        _fadeOutTimerHit = [NSDate dateWithTimeIntervalSince1970:0];
        
        CGRect frame = [UIScreen mainScreen].applicationFrame;
        _mediaItem = mediaItem;
        _moviePlayer = [[PlayerView alloc] initWithMediaItem:mediaItem];
        [self.view addSubview:_moviePlayer];
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            _controlBackground = [[UIView alloc] init];
            _skipLabel = [[UILabel alloc] init];
            _skipLabel.font = [UIFont fontWithName:@"Century Gothic" size:24.0f];
            _skipButton = [[UIButton alloc] init];
            _volumeView = [[MPVolumeView alloc] init];
            _eyeButton = [[UIButton alloc] init];
            _volumeImageView = [[UIImageView alloc] init];
            
            [self setIpadDisplay];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(didRotate:)
                                                         name:UIApplicationDidChangeStatusBarOrientationNotification
                                                       object:nil];
        } else {
            _controlBackground = [[UIView alloc] initWithFrame:CGRectMake(4, 7, 61, frame.size.height - 3)];
            
            _skipLabel = [[UILabel alloc] initWithFrame:CGRectMake(17, frame.size.height - 95, 34, 31)];
            [_skipLabel setTransform:CGAffineTransformMakeRotation(M_PI / 2)];
            _skipLabel.font = [UIFont fontWithName:@"Century Gothic" size:20.0f];
            
            _skipButton = [[UIButton alloc] initWithFrame:CGRectMake(13, frame.size.height - 55, 40, 37)];
            [_skipButton setTransform:CGAffineTransformMakeRotation(M_PI / 2)];
            
            _volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0, 0, frame.size.height - 237, 15)];
            _volumeView.center = CGPointMake(31,self.view.frame.size.height/2);
            _volumeView.transform = CGAffineTransformRotate(_volumeView.transform, M_PI / 2);
        
            _eyeButton = [[UIButton alloc] initWithFrame:CGRectMake(8, 28, 49, 39)];
            _eyeButton.transform = CGAffineTransformRotate(_eyeButton.transform, M_PI / 2);
            
            _volumeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 86, 42, 32)];
            _volumeImageView.transform = CGAffineTransformRotate(_volumeImageView.transform, M_PI / 2);
            
        }
        
        _skipLabel.textColor = [UIColor grayColor];
        _skipLabel.backgroundColor = [UIColor clearColor];
        [_skipLabel setAlpha:0.0];
        [self setSkipCount:0 total:0];
        
        _skipImage = [UIImage imageNamed:@"skip-01.png"];
        [_skipButton setImage:_skipImage forState:UIControlStateNormal];
        [_skipButton addTarget:self action:@selector(skipButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_skipButton setAlpha:0.0];
        [_skipButton setHitTestEdgeInsets:UIEdgeInsetsMake(-20, -20, -20, -20)];
        _skipButton.showsTouchWhenHighlighted = YES;
        _skipButton.enabled = NO;
        
        UIImage *eyeImage = [UIImage imageNamed:@"eye-01.png"];
        [_eyeButton setBackgroundImage:eyeImage forState:UIControlStateNormal];
        [_eyeButton addTarget:self action:@selector(eyeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_eyeButton setAlpha:0.0];
        [_eyeButton setHitTestEdgeInsets:UIEdgeInsetsMake(-20, -20, -20, -20)];
        _eyeButton.showsTouchWhenHighlighted = YES;
        _eyeButton.enabled = NO;
        
        [_eyeButton setHitTestEdgeInsets:UIEdgeInsetsMake(-10, -10, -10, -10)];
        _controlBackground.layer.cornerRadius = 5;
        _controlBackground.layer.masksToBounds = YES;
        _controlBackground.layer.borderColor = [UIColor grayColor].CGColor;
        _controlBackground.backgroundColor = [UIColor blackColor];
        _controlBackground.layer.borderWidth = 3.0f;
        [_controlBackground setAlpha:0.0];
        
        _fadeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _fadeButton.frame = frame;
        [_fadeButton addTarget:self action:@selector(fadeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [_volumeView setAlpha:0.0];
        [_volumeView sizeToFit];
        
        [_volumeImageView setAlpha:0.0];
        
        [self initialCheckVolume];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(volumeChanged:)
                                                     name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                                   object:nil];
        
        [self.view addSubview:_skipLabel];
        [self.view addSubview:_skipButton];
        [self.view addSubview:_controlBackground];
        [self.view addSubview:_fadeButton];
        [self.view addSubview:_volumeView];
        [self.view addSubview:_eyeButton];
        [self.view addSubview:_volumeImageView];
        [self.view bringSubviewToFront:_controlBackground];
        [self.view bringSubviewToFront:_skipLabel];
        [self.view bringSubviewToFront:_fadeButton];
        [self.view bringSubviewToFront:_skipButton];
        [self.view bringSubviewToFront:_volumeView];
        [self.view bringSubviewToFront:_eyeButton];
        [self.view bringSubviewToFront:_volumeImageView];
        
    }
    return self;
}


- (void)setIpadDisplay
{
    
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
    _controlBackground.frame = CGRectMake(10, frame.size.height - 85, frame.size.width - 20, 72);
    _fadeButton.frame = frame;
    _volumeView.frame = CGRectMake(0, 0, frame.size.width - 320, 15);
    _volumeView.center = CGPointMake(frame.size.width / 2, frame.size.height - 51);
    _eyeButton.frame = CGRectMake(25, frame.size.height - 75, 70, 56);
    _volumeImageView.frame = CGRectMake(108, frame.size.height - 65, 45, 33);
}

- (void)didRotate:(NSNotification *)notification {
    [self setIpadDisplay];

}

- (void)eyeButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)skipButtonPressed:(id)sender
{
    [self.delegate skipButtonPressed];
}

- (void)volumeChanged:(NSNotification *)notification
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [_skipLabel setAlpha:1.0];
    [_skipButton setAlpha:1.0];
    [_controlBackground setAlpha:0.75];
    [_volumeView setAlpha:1.0];
    [_eyeButton setAlpha:1.0];
    [_volumeImageView setAlpha:1.0];
    [UIView commitAnimations];
    if(_fadeOutTimer) {
        [_fadeOutTimer invalidate];
        _fadeOutTimer = nil;
    }
    _skipButton.enabled = YES;
    _eyeButton.enabled = YES;
    _fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fadeOut:) userInfo:nil repeats:NO];
    
    float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    [self changeVolumeIcon:volume];
}

- (void)fadeButtonPressed:(id)sender
{
    NSLog(@"Fade button pressed");
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [_skipLabel setAlpha:1.0];
    [_skipButton setAlpha:1.0];
    [_controlBackground setAlpha:0.75];
    [_volumeView setAlpha:1.0];
    [_eyeButton setAlpha:1.0];
    [_volumeImageView setAlpha:1.0];
    [UIView commitAnimations];
    if(_fadeOutTimer) {
        if(ABS([_fadeOutTimerHit timeIntervalSinceNow]) < 0.5) {
            // double tap
            _skipButton.enabled = YES;
            _eyeButton.enabled = YES;
            return;
        }
        [_fadeOutTimer invalidate];
        _fadeOutTimer = nil;
        [self fadeOut:nil];
    } else {
        _skipButton.enabled = YES;
        _eyeButton.enabled = YES;
        _fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(fadeOut:) userInfo:nil repeats:NO];
        _fadeOutTimerHit = [NSDate date];
    }
}

- (void)fadeOut:(NSTimer *)timer
{
    _fadeOutTimerHit = [NSDate dateWithTimeIntervalSince1970:0];
    [UIView animateWithDuration:0.5f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [_skipLabel setAlpha:0.0];
                         [_skipButton setAlpha:0.0];
                         [_controlBackground setAlpha:0.0];
                         [_volumeView setAlpha:0.0];
                         [_eyeButton setAlpha:0.0];
                         [_volumeImageView setAlpha:0.0];
                  }
                     completion:^(BOOL finished) {
                         _fadeOutTimer = nil;
                         _skipButton.enabled = NO;
                         _eyeButton.enabled = NO;
                  }];
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

#pragma mark - Volume Control

- (void)initialCheckVolume {
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    float volume = musicPlayer.volume;
    [self changeVolumeIcon:volume];
}

- (void)changeVolumeIcon: (float)volume{
    if (volume > .66) {
        _volumeImageView.image = [UIImage imageNamed:@"extrafullVolume-01.png"];
    } else if (volume <= .66 && volume > 0.33) {
        _volumeImageView.image = [UIImage imageNamed:@"fullVolume-01.png"];
    } else if (volume <= .33 && volume > 0.0) {
        _volumeImageView.image = [UIImage imageNamed:@"lowVolume-01.png"];
    } else {
        _volumeImageView.image = [UIImage imageNamed:@"muteVolume-01.png"];
    }
}
@end
