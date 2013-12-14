//
//  WBLocationManager.h
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Logic High Software All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#define kWBLocationManagerDesiredAccuracy 100

@interface WBLocationManager : CLLocationManager <CLLocationManagerDelegate>
// If current location is known returns a CLLocation object, otherwise will lock thread and get the current location.
// NSError possible if user denies access, can't be called the first time from main thread, unless you manually start
// Updating location, and wait until it is updated.
+ (id)currentLocationSync;

// Starts a location update
+ (void)beginLocationUpdate;
@end
