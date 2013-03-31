//
//  wViewController.m
//  LocationTest2
//
//  Created by Alex Chen on 3/30/13.
//  Copyright (c) 2013 Alex Chen. All rights reserved.
//

#import "wViewController.h"
#import <UIKit/UIKit.h>
#import "wCoreLocationController.h"

@implementation wViewController

@synthesize CLController = _CLController;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
	CLController = [[wCoreLocationController alloc] init];
	CLController.delegate = self;
    count = 0;
    buttonMode = 0;
    [CLController.locMgr startUpdatingLocation];
}

- (IBAction)startStopClearButton:(id)sender {
    if (buttonMode == 0) {
        buttonMode = 1;
        [sender setTitle:@"Stop" forState:UIControlStateNormal];
    } else if (buttonMode == 1) {
        buttonMode = 0;
        [sender setTitle:@"Start" forState:UIControlStateNormal];
    }
}

- (IBAction)mark:(id)sender {
    NSInteger temp = buttonMode;
    buttonMode = 0;
   
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Mark" message:@"Enter a comment:" delegate:self cancelButtonTitle:@"Add" otherButtonTitles:@"Cancel", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *alertTextField = [alert textFieldAtIndex:0];
    alertTextField.placeholder = @"(comment here)";
    [alert show];
    
    buttonMode = temp;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        if (count > 0) {
            textView.text = [NSString stringWithFormat:@"%@\n", textView.text];
        }
        textView.text = [NSString stringWithFormat:@"%@***%@***\n", textView.text, [[alertView textFieldAtIndex:0] text]];
    }
}

- (IBAction)clearButton:(id)sender {
    textView.text = @"";
    count = 0;
}

- (void)locationUpdate:(CLLocation *)location {
	latitudeLabel.text = [NSString stringWithFormat:@"latitude: %+.6f\u00B0", location.coordinate.latitude];
	longitudeLabel.text = [NSString stringWithFormat:@"longitude: %+.6f\u00B0", location.coordinate.longitude];
	altitudeLabel.text = [NSString stringWithFormat:@"altitude: %+.6fm", [location altitude]];
    
    horizontalAccuracyLabel.text = [NSString stringWithFormat:@"horizontal accuracy: %.2fm", location.horizontalAccuracy];
    verticalAccuracyLabel.text = [NSString stringWithFormat:@"vertical accuracy: %.2fm", location.verticalAccuracy];
    
    if (buttonMode == 1) {
        NSDate* now = [NSDate date];
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *dateComponents = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit  |  NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:now];
        NSInteger hour = [dateComponents hour];
        NSInteger minute = [dateComponents minute];
        NSInteger second = [dateComponents second];
        NSInteger month = [dateComponents month];
        NSInteger day = [dateComponents day];
        NSInteger year = [dateComponents year];
        if (count > 0) {
            textView.text = [NSString stringWithFormat:@"%@\n", textView.text];
        }
        textView.text = [NSString stringWithFormat:@"%@DATA POINT %d at %04d-%02d-%02d-%02d:%02d:%02d\n", textView.text, count, year, month, day, hour, minute, second];
        textView.text = [NSString stringWithFormat:@"%@latitude: %+.6f\nlongitude: %+.6f\naltitude: %+.6f\nhorizontal accuracy: %.2f\nvertical accuracy: %.2f\n", textView.text, location.coordinate.latitude, location.coordinate.longitude, [location altitude], location.horizontalAccuracy, location.verticalAccuracy];
        count++;
    }
}

- (void)locationError:(NSError *)error {
	altitudeLabel.text = [error description];
}

@end
