//
//  wCoreLocationController.h
//  LocationTest2
//
//  Created by Alex Chen on 3/30/13.
//  Copyright (c) 2013 Alex Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

// Differs from wCoreLocationController in that it tries not to use GPS by using a different kind of LocationManager.

@protocol wCoreLocationControllerDelegate2
@required
- (void)locationUpdate2: (CLLocation *)location;
- (void)locationError2: (NSError *)error;
@end

@interface wCoreLocationController2 : NSObject <CLLocationManagerDelegate> {
    CLLocationManager *locMgr;
    id delegate;
}

@property (strong, nonatomic) CLLocationManager *locMgr;
@property (strong, nonatomic) id delegate;

@end
