//
//  ViewController.m
//  sampleQueueIphone
//
//  Created by Abdullah Bakhach on 9/4/12.
//  Copyright (c) 2012 Amazon. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)showMediaPicker:(id)sender {
    MPMediaPickerController *mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAny];
    mediaPicker.delegate = self;
    mediaPicker.allowsPickingMultipleItems = NO;
    mediaPicker.prompt = @"Select song to play";
    
    [self presentViewController:mediaPicker animated:YES completion:nil];
}

- (void) mediaPicker: (MPMediaPickerController *)mediaPicker didPickMediaItems: (MPMediaItemCollection *) mediaItemCollection
{
    NSLog(@"didPickMediaItems:");
    if (mediaItemCollection) {
        
        MPMediaItem *chosenItem = mediaItemCollection.items[0];
        
        _songURL = [chosenItem valueForProperty: MPMediaItemPropertyAssetURL];
        NSLog(@"url = %@", _songURL);
        //        [musicPlayer setQueueWithItemCollection: mediaItemCollection];
        //        [musicPlayer play];
        
        
        Streamer *streamer = [[Streamer alloc] initWithURL:_songURL];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker
{
    NSLog(@"mediaPickerDidCancel");
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
