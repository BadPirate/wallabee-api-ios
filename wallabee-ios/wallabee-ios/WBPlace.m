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
#import "WBItem.h"

@interface WBPlace ()
@property (nonatomic,retain) NSDictionary *data;
@property (nonatomic,retain) NSMutableArray *items;
@end

@implementation WBPlace
@synthesize  data, items;
- (id)initWithIdentifier:(NSInteger)placeIdentifier
{
    self = [super init];
    _placeIdentifier = placeIdentifier;
    return self;
}

+ (void)nearby_a:(void(^)(id result))handler
{
    // Run in background, so that waiting for location doesn't jam up main thread.
    
    [[[WBSession instance] asyncRequestQueue] addOperationWithBlock:^{
        CLLocation *currentLocation = [WBLocationManager currentLocationSync];
        if(![currentLocation isKindOfClass:[CLLocation class]])
        {
            handler(currentLocation); // error
            return;
        }
        id result = [self nearLocation_s:currentLocation.coordinate];
        performBlockMainThread(handler, result);
    }];
}

+ (id)nearLocation_s:(CLLocationCoordinate2D)coordinate
{
    NSString *requestString = [NSString stringWithFormat:@"/places?lat=%f&lng=%f",coordinate.latitude,coordinate.longitude];
    NSDictionary *result = [WBSession makeSyncRequest:requestString];
    if(![result isKindOfClass:[NSDictionary class]])
    {
        return result;
    }
    // Parse it!
    NSArray *resultArray = [result objectForKey:@"places"];
    NSMutableArray *places = [NSMutableArray arrayWithCapacity:[resultArray count]];
    for(NSDictionary *placeDictionary in resultArray)
    {
        [places addObject:[self placeWithData:placeDictionary]];
    }
    return places;
}

+ (id)placeWithIdentifier:(NSInteger)placeIdentifier
{
    WBSession *session = [WBSession instance];
    NSString *identifierString = [NSString stringWithFormat:@"%d",placeIdentifier];
    WBPlace *place = [[session cachedPlaces] objectForKey:identifierString];
    if(place) return place;
    place = [[self alloc] initWithIdentifier:placeIdentifier];
    [[session cachedPlaces] setObject:place forKey:identifierString];
    return place;
}

+ (id)placeWithData:(NSDictionary *)data
{
    NSString *identifierString = [data objectForKey:@"id"];
    NSAssert1(identifierString,@"No identifier string in data - %@",data);
    WBPlace *place = [self placeWithIdentifier:[identifierString integerValue]];
    place.data = data;
    return place;
}

- (id)loadPlaceData
{
    NSString *requestString = [NSString stringWithFormat:@"/places/%u",[self placeIdentifier]];
    id response = [WBSession makeSyncRequest:requestString];
    if([response isKindOfClass:[NSDictionary dictionary]])
    {
        self.data = response;
        return response;
    }
    else
        return response;
}

- (NSInteger)itemCount
{
    return [[data objectForKey:@"item_count"] intValue];
}

- (id)items_s
{
    if([self itemCount] == 0)
        return [NSMutableArray array];
    @synchronized(self)
    {
        if(!items)
            items = [NSMutableArray array];
    }
    @synchronized(items)
    {
        if([items count] > 0)
            return items;
        NSString *requestString = [NSString stringWithFormat:@"/places/%u/items",[self placeIdentifier]];
        NSDictionary *result = [WBSession makeSyncRequest:requestString];
        if(![result isKindOfClass:[NSDictionary class]])
            return result;
        NSArray *itemsArray = [result objectForKey:@"items"];
        for(NSDictionary *itemDictionary in itemsArray)
        {
            WBItem *item = [[WBItem alloc] initWithDictionary:itemDictionary];
            item.place = self;
            [items addObject:item];
        }
        return items;
    }
}

- (id)name_s
{
    if(!data)
    {
        id result = [self loadPlaceData];
        if(![result isKindOfClass:[NSDictionary class]])
            return result;
    }
    return [data objectForKey:@"name"];
}

- (CLLocationCoordinate2D)coordinate_s
{
    if(!data)
    {
        id result = [self loadPlaceData];
        if(![result isKindOfClass:[NSDictionary class]])
            return CLLocationCoordinate2DMake(0, 0);
    }
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [[data objectForKey:@"lat"] doubleValue];
    coordinate.longitude = [[data objectForKey:@"lng"] doubleValue];
    return coordinate;
}

- (NSUInteger)placeIdentifier
{
    if(_placeIdentifier)
        return _placeIdentifier;
    if([data objectForKey:@"id"])
        return [[data objectForKey:@"id"] intValue];
    return -1;
}
@end
