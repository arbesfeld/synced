//
//  wViewController.h
//  LocationTest2
//
//  Created by Alex Chen on 3/30/13.
//  Copyright (c) 2013 Alex Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "wCoreLocationController.h"

@interface wViewController : UIViewController <wCoreLocationControllerDelegate> {
	wCoreLocationController *CLController;
    IBOutlet UILabel *latitudeLabel;
    IBOutlet UILabel *longitudeLabel;
    IBOutlet UILabel *altitudeLabel;
    IBOutlet UILabel *horizontalAccuracyLabel;
    IBOutlet UILabel *verticalAccuracyLabel;
    
    NSInteger count;
    NSInteger buttonMode; // 0=start, 1=stop, 2=clear
    IBOutlet UITextView *textView;
}

@property (nonatomic, retain) wCoreLocationController *CLController;

@end