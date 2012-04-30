//
//  WBSet.m
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Logic High Software All rights reserved.
//

#import "WBSet.h"
#import "WBUser.h"
#import "WBSession.h"
#import "WBItem.h"

@interface WBSet ()
@property (nonatomic,retain) NSDictionary *data;
@property (nonatomic,retain) WBUser *user;
@property (nonatomic,retain) NSMutableArray *items;
@property (nonatomic,retain) NSLock *fetchingItems;
@end

@implementation WBSet
@synthesize data, user, items, fetchingItems;

- (id)initSetWithData:(NSDictionary *)dataDictionary user:(WBUser *)userPassed
{
    self = [super init];
    data = dataDictionary;
    user = userPassed;
    fetchingItems = [[NSLock alloc] init];
    return self;
}

- (BOOL)isUserSet
{
    if(user)
        return YES;
    return NO;
}

- (NSInteger)setIdentifier
{
    return [[data objectForKey:@"id"] intValue];
}

- (id)items_s
{
    if([self isUserSet])
    {
        NSString *requestString = [NSString stringWithFormat:@"/users/%u/sets/%u",[user userIdentifier],[self setIdentifier]];
        NSDictionary *result = [WBSession makeSyncRequest:requestString];
        if(![result isKindOfClass:[NSDictionary class]])
        {
            return result;
        }
        NSArray *itemsArray = [result objectForKey:@"items"];
        items = [NSMutableArray arrayWithCapacity:[itemsArray count]];
        for(NSDictionary *itemDictionary in itemsArray)
        {
            WBItem *item = [[WBItem alloc] initWithDictionary:itemDictionary];
            item.user = user;
            item.set = self;
            [items addObject:item];
        }
        return items;
    }
    else {
        NSLog(@"Error - Tried to get items from a non-user set");
        return nil; // TODO: Make work for non-user sets
    }
}

- (id)items:(void(^)(id result))asyncHandler
{
    if(items) return items;
    NSOperationQueue *asyncRequestQueue = [[WBSession instance] asyncRequestQueue];
    
    @synchronized(self)
    {
        if(![fetchingItems tryLock])
        {
            [asyncRequestQueue addOperationWithBlock:^{
                [fetchingItems lock];
                [fetchingItems unlock];
                performBlockMainThread(asyncHandler, [self items_s]);
            }];
        }
        return nil; // Async
    }

    [asyncRequestQueue addOperationWithBlock:^{
        performBlockMainThread(asyncHandler, [self items_s]);
    }];
    return nil; // Will handle at a later date
}

- (id)parseCollectedItems:(NSArray *)allItems
{
    if(![allItems isKindOfClass:[NSArray class]])
        return allItems;
    NSMutableArray *collectedItems = [NSMutableArray array];
    for(WBItem *item in allItems)
    {
        if([item isCollected])
            [collectedItems addObject:item];
    }
    return collectedItems;
}

- (id)collectedItems:(void(^)(id result))asyncHandler;
{
    NSArray *allItems = [self items:^(id result) {
        asyncHandler([self parseCollectedItems:result]);
    }];  
    if(allItems)
        return [self parseCollectedItems:allItems];
    return nil; // Async
}
@end
