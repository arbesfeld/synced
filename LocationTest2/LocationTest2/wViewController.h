//
//  wViewController.h
//  LocationTest2
//
//  Created by Alex Chen on 3/30/13.
//  Copyright (c) 2013 Alex Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "wCoreLocationController.h"
#import "wCoreLocationController2.h"

@interface wViewController : UIViewController <wCoreLocationControllerDelegate, wCoreLocationControllerDelegate2> {
	wCoreLocationController *CLController;
    IBOutlet UILabel *latitudeLongitudeLabel;
    IBOutlet UILabel *altitudeLabel;
    IBOutlet UILabel *accuracyLabel;
    
    wCoreLocationController2 *CLController2;
    IBOutlet UILabel *latitudeLongitudeLabel2;
    IBOutlet UILabel *altitudeLabel2;
    IBOutlet UILabel *accuracyLabel2;
    
    NSInteger count;
    NSInteger count2;
    NSInteger buttonMode; // 0=start, 1=stop, 2=clear
    IBOutlet UITextView *textView;
    IBOutlet UITextView *textView2;
}

@property (nonatomic, retain) wCoreLocationController *CLController;
@property (nonatomic, retain) wCoreLocationController2 *CLController2;

@end