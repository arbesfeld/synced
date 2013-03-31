//
//  wCoreLocationController.h
//  LocationTest2
//
//  Created by Alex Chen on 3/30/13.
//  Copyright (c) 2013 Alex Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol wCoreLocationControllerDelegate
@required
- (void)locationUpdate: (CLLocation *)location;
- (void)locationError: (NSError *)error;
@end

@interface wCoreLocationController : NSObject <CLLocationManagerDelegate> {
    CLLocationManager *locMgr;
    id delegate;
}

@property (strong, nonatomic) CLLocationManager *locMgr;
@property (strong, nonatomic) id delegate;

@end
