//
//  UIDownloadBarAppDelegate.h
//  UIDownloadBar
//
//  airShare
//  
//

#import <UIKit/UIKit.h>
#import "UIDownloadBar.h"



@interface UIDownloadBarAppDelegate : NSObject <UIApplicationDelegate, UIDownloadBarDelegate> {
    UIWindow *window;
	
	UIDownloadBar *bar;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end
