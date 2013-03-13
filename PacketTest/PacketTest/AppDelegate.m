//
//  AppDelegate.m
//  sampleQueueIphone
//
//  Created by Abdullah Bakhach on 9/4/12.
//  Copyright (c) 2012 Amazon. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    //self.mediaPickerController = [[MediaPickerController alloc] init];
    //[self.mediaPickerController showMediaPicker:self];
    
    self.viewController = [[ViewController alloc] init];
    
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    // Insert code here to initialize your application
    
    
    [self.viewController showMediaPicker:self];
    
    return YES;
}

@end
