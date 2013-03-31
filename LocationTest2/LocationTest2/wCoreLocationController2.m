//
//  wCoreLocationController.m
//  LocationTest2
//
//  Created by Alex Chen on 3/30/13.
//  Copyright (c) 2013 Alex Chen. All rights reserved.
//

#import "wCoreLocationController2.h"

@implementation wCoreLocationController2

@synthesize locMgr = _locMgr;
@synthesize delegate;

- (id)init {
	self = [super init];
    
	if(self != nil) {
		self.locMgr = [[CLLocationManager alloc] init];
		self.locMgr.delegate = self;
        
        //The location manager object manages power aggressively by turning off hardware when it is not needed. For example, setting the desired accuracy for location events to one kilometer gives the location manager the flexibility to turn off GPS hardware and rely solely on the WiFi or cell radio.
        
        _locMgr.desiredAccuracy = kCLLocationAccuracyKilometer; // BestForNavigation
        _locMgr.distanceFilter = kCLHeadingFilterNone;
	}
    
	return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	if([self.delegate conformsToProtocol:@protocol(wCoreLocationControllerDelegate2)]) {
		[self.delegate locationUpdate2:newLocation];
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	if([self.delegate conformsToProtocol:@protocol(wCoreLocationControllerDelegate2)]) {
		[self.delegate locationError2:error];
	}
}

@end
