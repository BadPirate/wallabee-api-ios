//
//  WBLocationManager.m
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Logic High Software All rights reserved.
//

#import "WBLocationManager.h"

@interface WBLocationManager ()
@property (nonatomic, retain) CLLocation *currentLocation;
@property (nonatomic, retain) NSError *locationError;
@end

@implementation WBLocationManager
@synthesize currentLocation, locationError;

+ (WBLocationManager *)instance
{
    __strong static WBLocationManager *_instance = nil;

    if([NSThread currentThread] != [NSThread mainThread])
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [WBLocationManager instance];
        });
        return _instance;
    }
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        _instance = [[WBLocationManager alloc] init]; // or some other init method
        _instance.delegate = _instance;
    });
    return _instance;
}


+ (void)beginLocationUpdate
{
    WBLocationManager *instance = [self instance];
    [instance setDesiredAccuracy:kWBLocationManagerDesiredAccuracy];
    [instance startUpdatingLocation];
}

+(id)currentLocationSync
{
    WBLocationManager *instance = [self instance];
    BOOL firstRunOnMainThread = !instance.currentLocation && [NSThread currentThread] == [NSThread mainThread];
    NSAssert(!firstRunOnMainThread,@"currentLocationSync can't be called from main thread the first time it is called");
    @synchronized (self)
    {
        if(instance.currentLocation)
            return instance.currentLocation;
        if(![self locationServicesEnabled])
            return [NSError errorWithDomain:@"LOCATION" code:0 userInfo:[NSDictionary dictionaryWithObject:@"Location information not available"
                                                                                                    forKey:NSLocalizedDescriptionKey]];
        [self beginLocationUpdate];
        while(!instance.currentLocation && !instance.locationError)
        {
            [NSThread sleepForTimeInterval:0.2];
        }
        id response = instance.currentLocation;
        if(instance.locationError)
        {
            response = instance.locationError;
            instance.locationError = nil;
        }
        return response;
    }
}

#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    currentLocation = newLocation;
}

- (void)locationManager: (CLLocationManager *)manager
       didFailWithError: (NSError *)error
{
    locationError = error;
}
@end
