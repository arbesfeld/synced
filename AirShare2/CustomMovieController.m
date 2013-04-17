//
//  CustomMovieController.m
//  AirShare2
//
//  Created by mata on 4/17/13.
//  Copyright (c) 2013 Matthew Arbesfeld. All rights reserved.
//

#import "CustomMovieController.h"

@implementation CustomMovieController

- (id)initWithContentURL:(NSURL *)url
{
    self = [super initWithContentURL:url];
    if(self) {
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:NO];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
        
        [self.view setBounds:CGRectMake(20, 0, UIScreen.mainScreen.bounds.size.height, UIScreen.mainScreen.bounds.size.width+20)];
        [self.view setCenter:CGPointMake(UIScreen.mainScreen.bounds.size.width / 2, UIScreen.mainScreen.bounds.size.height/2)];
        [self.view setTransform:CGAffineTransformMakeRotation(M_PI / 2)];
        self.controlStyle = MPMovieControlStyleNone;
    }
    return self;
}

- (void)stop
{
    [super stop];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}
@end
