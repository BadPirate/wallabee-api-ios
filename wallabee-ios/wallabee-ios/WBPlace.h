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
    NSInteger _placeIdentifier;
}
// Gets the users location, and returns an NSMutableArray of WBPlace objects or NSError to the handler
+ (void)nearby_a:(void(^)(id result))handler;

// Makes a synchronous call and returns the result near a particular location
+ (id)nearLocation_s:(CLLocationCoordinate2D)coordinate;

// Return value can be WBPlace object or NSError
+ (id)placeWithIdentifier:(NSInteger)placeIdentifier;

// Synchronous - Returns an NSMutableArray of WBItem objects or NSError
- (id)items_s;

// Returns the item count
- (NSInteger)itemCount;

// Returns the NSString name of a place, or NSError
- (id)name_s;

// Returns the coordinate of place, with coordinate 0/0 if there is an error
- (CLLocationCoordinate2D)coordinate_s;

// Returns the identifier for this place
- (NSUInteger)placeIdentifier;
@end
