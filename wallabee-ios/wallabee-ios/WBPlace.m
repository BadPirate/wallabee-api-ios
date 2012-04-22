//
//  WBPlace.m
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Good. All rights reserved.
//

#import "WBPlace.h"
#import "WBSession.h"
#import <CoreLocation/CoreLocation.h>
#import "WBLocationManager.h"

@interface WBPlace ()
@property (nonatomic,retain) NSDictionary *data;
@end

@implementation WBPlace
@synthesize identifier = _identifier, data;
- (id)initWithIdentifier:(NSUInteger)identifier
{
    self = [super init];
    _identifier = identifier;
    return self;
}

+ (void)nearbyAsync:(void(^)(id result))handler
{
    // Run in background, so that waiting for location doesn't jam up main thread.
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       CLLocation *currentLocation = [WBLocationManager currentLocationSync];
                       if(![currentLocation isKindOfClass:[CLLocation class]])
                       {
                           handler(currentLocation); // error
                           return;
                       }
                       id result = [self nearLocationSync:currentLocation];
                       handler(result);
                   });
}

+ (id)nearLocationSync:(CLLocation *)location
{
    NSString *requestString = [NSString stringWithFormat:@"/places?lat=%f&lng=%f",location.coordinate.latitude,location.coordinate.longitude];
    id result = [WBSession makeSyncRequest:requestString];
    if(![result isKindOfClass:[NSArray class]])
    {
        return result;
    }
    // Parse it!
    NSArray *resultArray = (NSArray *)result;
    NSMutableArray *places = [NSMutableArray arrayWithCapacity:[resultArray count]];
    for(NSDictionary *placeDictionary in resultArray)
    {
        [places addObject:[self placeWithData:placeDictionary]];
    }
    return places;
}

+ (id)placeWithIdentifier:(NSUInteger)placeIdentifier
{
    WBPlace *place = [[self alloc] initWithIdentifier:placeIdentifier];
    return place;
}

+ (id)placeWithData:(NSDictionary *)data
{
    NSString *identifierString = [data objectForKey:@"id"];
    NSAssert1(identifierString,@"No identifier string in data - %@",data);
    WBPlace *place = [[self alloc] initWithIdentifier:[identifierString integerValue]];
    place.data = data;
    return place;
}

- (void)loadPlaceData
{
    NSString *requestString = [NSString stringWithFormat:@"/places/%u",_identifier];
    id response = [WBSession makeSyncRequest:requestString];
    if(![response isKindOfClass:[NSDictionary dictionary]])
        self.data = response;
}
@end
