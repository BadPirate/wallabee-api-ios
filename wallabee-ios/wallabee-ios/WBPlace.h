//
//  WBPlace.h
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Good. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface WBPlace : NSObject
{
    @private
    NSUInteger _identifier;
}
@property (nonatomic, readonly) NSUInteger identifier;

// Gets the users location, and returns an NSMutableArray of WBPlace objects or NSError to the handler
+ (void)nearbyAsync:(void(^)(id result))handler;

// Makes a synchronous call and returns the result near a particular location
+ (id)nearLocationSync:(CLLocation *)location;

// Return value can be WBPlace object or NSError
+ (id)placeWithIdentifier:(NSUInteger)identifier;
@end
