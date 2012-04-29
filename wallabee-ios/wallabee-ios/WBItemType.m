//
//  WBItemType.m
//  PirateWalla
//
//  Created by Kevin Lohman on 4/29/12.
//  Copyright (c) 2012 Good. All rights reserved.
//

#import "WBItemType.h"
#import "WBSession.h"

@interface WBItemType ()
- (id)initWithTypeIdentifier:(NSInteger)typeIdentifierGiven;
- (void)loadData:(void(^)(id result))handler;
@property (nonatomic, assign) NSInteger typeIdentifier;
@property (nonatomic, retain) NSMutableArray *mix;
@property (nonatomic, retain) NSDictionary *data;
@property (nonatomic, retain) NSLock *fetchingData;
@end

@implementation WBItemType
@synthesize typeIdentifier, mix, data, fetchingData;

- (id)initWithTypeIdentifier:(NSInteger)typeIdentifierGiven
{
    self = [super init];
    typeIdentifier = typeIdentifierGiven;
    fetchingData = [[NSLock alloc] init];
    return self;
}

+ (id)itemTypeForTypeIdentifier:(NSInteger)typeIdentifierGiven
{
    NSMutableDictionary *cachedItemTypes = [[WBSession instance] cachedItemTypes];
    NSString *typeIdentifierString = [NSString stringWithFormat:@"%d",typeIdentifierGiven];
    WBItemType *cachedItemType = [cachedItemTypes objectForKey:typeIdentifierString];
    if(cachedItemType)
        return cachedItemType;
    cachedItemType = [[self alloc] initWithTypeIdentifier:typeIdentifierGiven];
    [cachedItemTypes setObject:cachedItemType forKey:typeIdentifierString];
    return cachedItemType;
}

- (NSInteger)typeIdentifier
{
    return typeIdentifier;
}

- (void)loadData:(void (^)(id result))handler
{
    @synchronized(self)
    {
        if(![fetchingData tryLock])
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [fetchingData lock];
                [fetchingData unlock];
                handler(data);
            });
            return; // Only one fetch at a time
        }
    }
    
    NSString *requestString = [NSString stringWithFormat:@"/itemtypes/%d",[self typeIdentifier]];
    [WBSession makeAsyncRequest:requestString result:^(id response) {
        if([response isKindOfClass:[NSDictionary class]])
            data = response;
        [fetchingData unlock];
        performBlockMainThread(handler, response);
    }];
}

- (id)mix:(void(^)(id result))asyncHandler
{
    if(mix) return mix;
    if(data)
    {
        mix = [data objectForKey:@"mix"];
        return mix;
    }
    [self loadData:^(id result) {
        if(![result isKindOfClass:[NSDictionary class]])
        {
            performBlockMainThread(asyncHandler, result); // error
            return;
        }
        mix = [result objectForKey:@"mix"];
        performBlockMainThread(asyncHandler, mix);
    }];
    return nil; // Async required
}

- (id)name:(void(^)(id result))asyncHandler
{
    if(data)
        return [data objectForKey:@"name"];
    [self loadData:^(id result) {
        if(![result isKindOfClass:[NSDictionary class]])
        {
            performBlockMainThread(asyncHandler, result);
            return;
        }
        performBlockMainThread(asyncHandler, [data objectForKey:@"name"]);
    }];
    return nil;
}

@end
