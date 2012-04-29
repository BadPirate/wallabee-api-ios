//
//  WBSet.m
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Good. All rights reserved.
//

#import "WBSet.h"
#import "WBUser.h"
#import "WBSession.h"
#import "WBItem.h"

@interface WBSet ()
@property (nonatomic,retain) NSDictionary *data;
@property (nonatomic,retain) WBUser *user;
@property (nonatomic,retain) NSMutableArray *items;
@end

@implementation WBSet
@synthesize data, user, items;

- (id)initSetWithData:(NSDictionary *)dataDictionary user:(WBUser *)userPassed
{
    self = [super init];
    data = dataDictionary;
    user = userPassed;
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

- (id)items:(void(^)(id result))asyncHandler
{
    if(items) return items;
    NSOperationQueue *asyncRequestQueue = [[WBSession instance] asyncRequestQueue];
        
    [asyncRequestQueue addOperationWithBlock:^{
        NSString *requestString = nil;
        if([self isUserSet])
        {
            requestString = [NSString stringWithFormat:@"/users/%u/sets/%d",[user userIdentifier],[self setIdentifier]];
        }
        else {
            requestString = [NSString stringWithFormat:@"/sets/%d",[self setIdentifier]];
        }
        NSDictionary *result = [WBSession makeSyncRequest:requestString];
        if(![result isKindOfClass:[NSDictionary class]])
        {
            performBlockMainThread(asyncHandler, result);
            return;
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
        performBlockMainThread(asyncHandler, items);
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

+ (id)allSets:(void(^)(id result))asyncHandler
{
    static NSMutableArray *allSets = nil;
    @synchronized(self)
    {
        if(!allSets)
            allSets = [NSMutableArray array];
    }
    if([allSets count] > 0) return allSets;
    
    // We're empty.. Gotta build it
    [[[WBSession instance] asyncRequestQueue] addOperationWithBlock:^{
        @synchronized(allSets)
        {
            if([allSets count] > 0)
            {
                performBlockMainThread(asyncHandler, allSets); // Another thread got it.
                return;
            }
            NSDictionary *setListDictionary = [WBSession makeSyncRequest:@"/sets"];
            if(![setListDictionary isKindOfClass:[NSDictionary class]])
            {
                performBlockMainThread(asyncHandler, setListDictionary); // Error
                return;
            }
            NSArray *setDictionaryArray = [setListDictionary objectForKey:@"sets"];
            NSMutableArray *allSetsTemp = [NSMutableArray arrayWithCapacity:[setDictionaryArray count]];
            for(NSDictionary *setDictionary in setDictionaryArray)
            {
                WBSet *set = [[WBSet alloc] initSetWithData:setDictionary user:nil];
                [allSetsTemp addObject:set];
            }
            [allSets addObjectsFromArray:allSetsTemp];
            performBlockMainThread(asyncHandler, allSets);
        }
    }];
    return nil;
}
@end
