//
//  ViewController.h
//  sampleQueueIphone
//
//  Created by Abdullah Bakhach on 9/4/12.
//  Copyright (c) 2012 Amazon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Streamer.h"
@interface ViewController : UIViewController <MPMediaPickerControllerDelegate>

@property (strong, nonatomic) NSURL *songURL;

- (void)showMediaPicker:(id)sender;

@end
