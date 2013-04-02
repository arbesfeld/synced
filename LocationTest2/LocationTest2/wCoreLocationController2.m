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
        //[self.locMgr startMonitoringSignificantLocationChanges];
        
        _locMgr.desiredAccuracy = kCLLocationAccuracyKilometer;
        _locMgr.distanceFilter = kCLHeadingFilterNone;
        
        [_locMgr startUpdatingLocation];
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
