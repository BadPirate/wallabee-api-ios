//
//  WBUser.m
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Logic High Software All rights reserved.
//

#import "WBUser.h"
#import "WBSession.h"
#import "WBSet.h"
#import "WBItem.h"
#import "WBItemType.h"

@interface WBUser ()
@property (nonatomic, retain) NSDictionary *data;
@property (nonatomic, assign) NSInteger completedSets;
@property (nonatomic, retain) NSMutableArray *collectedItems, *sets, *missingItemTypes, *comboItemsNeeded;
@property (nonatomic, retain) NSLock *fetchingCollectedItems, *fetchingMissingItemTypes, *fetchingComboItems;
@end

@implementation WBUser
@synthesize data, completedSets, collectedItems, sets, fetchingCollectedItems, fetchingMissingItemTypes, missingItemTypes, comboItemsNeeded, fetchingComboItems;
- (id)initWithData:(NSDictionary *)dataDictionary
{
    self = [super init];
    self.data = dataDictionary;
    self.completedSets = -1; // Need to fetch data
    self.fetchingCollectedItems = [[NSLock alloc] init];
    self.fetchingMissingItemTypes = [[NSLock alloc] init];
    self.fetchingComboItems = [[NSLock alloc] init];
    return self;
}

+ (id)userWithName_s:(NSString *)userName
{
    NSString *requestString = [NSString stringWithFormat:@"/users/%@",userName];
    NSDictionary *response = [WBSession makeSyncRequest:requestString];
    if(![response isKindOfClass:[NSDictionary class]])
        return response; // Error
    return [[WBUser alloc] initWithData:response];
}

- (id)name_s
{
    NSString *name = [data objectForKey:@"name"];
    if(name)
        return name;
    return [NSError errorWithDomain:@"WALLABEE" code:0 userInfo:[NSDictionary dictionaryWithObject:@"Name value not present in data" forKey:NSLocalizedDescriptionKey]];
}

- (id)sets_s
{
    if(sets) return sets;
    
    NSString *requestString = [NSString stringWithFormat:@"/users/%@/sets",[self name_s]];
    NSDictionary *response = [WBSession makeSyncRequest:requestString];
    if(![response isKindOfClass:[NSDictionary class]])
    {
        return response; // Error
    }
    NSArray *setsArray = [response objectForKey:@"sets"];
    sets = [NSMutableArray arrayWithCapacity:[setsArray count]];
    
    for(NSDictionary *setDictionary in setsArray)
    {
        WBSet *set = [[WBSet alloc] initSetWithData:setDictionary user:self];
        [sets addObject:set];
    }
    
    completedSets = [[response objectForKey:@"completedSets"] intValue];
    
    return sets;
}

- (id)sets:(void(^)(id result))asyncHandler
{
    if(sets) return sets;
        
    NSOperationQueue *asyncRequestQueue = [[WBSession instance] asyncRequestQueue];
    
    [asyncRequestQueue addOperationWithBlock:^{
        performBlockMainThread(asyncHandler, [self sets_s]);
    }];
    return nil; // Result will be returned by async handler
}

- (NSInteger)userIdentifier
{
    return [[data objectForKey:@"id"] intValue];
}

- (id)parseCollectedItems:(NSArray *)userSets asyncHandler:(void(^)(id result))asyncHandler
{
    if(![userSets isKindOfClass:[NSArray class]])
    {
        [fetchingCollectedItems unlock];
        return userSets; // Error, or nil
    }
    
    NSMutableArray *parsedSets = [NSMutableArray arrayWithCapacity:[userSets count]];
    NSMutableArray *errorResults = [NSMutableArray array];
    for(WBSet *set in userSets)
    {
        NSArray *result = [set collectedItems:^(id result) {
            if(![result isKindOfClass:[NSArray class]])
            {
                @synchronized(errorResults)
                {
                    [errorResults addObject:result];
                    if([errorResults count] == 1)
                    {
                        performBlockMainThread(asyncHandler, result);
                        [fetchingCollectedItems unlock];
                    }
                }
            }
            else {
                @synchronized(collectedItems)
                {
                    [collectedItems addObjectsFromArray:result];
                    [parsedSets addObject:result];
                    if([parsedSets count] == [userSets count])
                    {
                        // Parsed them all successfully!
                        performBlockMainThread(asyncHandler, collectedItems);
                        [fetchingCollectedItems unlock];
                    }
                }
            }
        }];
        if([result isKindOfClass:[NSArray class]])
        {
            @synchronized(collectedItems)
            {
                [collectedItems addObjectsFromArray:result];
                [parsedSets addObject:result];
            }
        }
        else if(result != nil)
        {
            @synchronized(errorResults)
            {
                [errorResults addObject:result];
            }
        }
    }
    if([errorResults count] == [userSets count])
    {
        [fetchingCollectedItems unlock];
        return [errorResults objectAtIndex:0]; // All Errored out
    }
    if([parsedSets count] == [userSets count])
    {
        [fetchingCollectedItems unlock];
        return collectedItems; // All sets previously parsed
    }
    return nil; // Will return async.
}

- (id)collectedItems_s
{
    if(collectedItems) return collectedItems;
    
    NSMutableArray *allSets = [self sets_s];
    if(![allSets isKindOfClass:[NSMutableArray class]])
        return allSets; // Error
    NSMutableArray *tempCollectedItems = [NSMutableArray array];
    for(WBSet *set in allSets)
    {
        NSMutableArray *setItems = [set items_s];
        if(![setItems isKindOfClass:[NSArray class]])
            return setItems; // Error
        for(WBItem *item in setItems)
            if(![[item name] isEqualToString:@"?"])
                [tempCollectedItems addObject:item];
    }
    collectedItems = tempCollectedItems;
    return collectedItems;
}

- (id)collectedItems:(void(^)(id result))asyncHandler
{
    NSOperationQueue *asyncQueue = [[WBSession instance] asyncRequestQueue];
    if(collectedItems) return collectedItems;
    @synchronized(self)
    {
        if(![fetchingCollectedItems tryLock])
        {
            [asyncQueue addOperationWithBlock:^{
                [fetchingCollectedItems lock];
                [fetchingCollectedItems unlock];
                performBlockMainThread(asyncHandler, [self collectedItems_s]);
            }];
        }
    }
    
    [asyncQueue addOperationWithBlock:^{
        performBlockMainThread(asyncHandler, [self collectedItems_s]);
        [fetchingCollectedItems unlock];
    }];
    return nil;
}

- (id)parseCollectedItemsByType:(NSMutableArray *)allCollectedItems handler:(void(^)(id result))asyncHandler
{
    if([allCollectedItems count] == 0)
        return allCollectedItems;
    
    NSMutableDictionary *collectedItemsByType = [NSMutableDictionary dictionary];
    for(WBItem *item in allCollectedItems)
    {
        NSString *typeString = [NSString stringWithFormat:@"%d",[item typeIdentifier]];
        NSMutableArray *typeArray = [collectedItemsByType objectForKey:typeString];
        if(!typeArray)
        {
            typeArray = [NSMutableArray arrayWithCapacity:1];
            [collectedItemsByType setObject:typeArray forKey:typeString];
        }
        [typeArray addObject:item];
    }
    return collectedItemsByType;
}

- (id)collectedItemsByType:(void(^)(id result))asyncHandler
{
    NSMutableArray *allCollectedItems = [self collectedItems:^(id result) {
        [self parseCollectedItemsByType:result handler:asyncHandler];
    }];
    if(allCollectedItems)
        return [self parseCollectedItemsByType:allCollectedItems handler:asyncHandler]; // Nil or error
    return nil;
}

- (void)refreshCollection_a:(void(^)(id result))asyncHandler
{
    collectedItems = nil;
    sets = nil;
    [self collectedItems:asyncHandler];
}

- (id)missingItemTypes_s
{
    if(missingItemTypes) return missingItemTypes;
    NSMutableArray *userSets = [self sets_s];
    NSMutableArray *tempMissingItemTypes = [NSMutableArray array];
    
    if(![userSets isKindOfClass:[NSMutableArray class]])
        return userSets;
    
    for(WBSet *set in userSets)
    {
        NSMutableArray *setItems = [set items_s];
        if(![setItems isKindOfClass:[NSArray class]])
            return setItems; // Error
        
        for(WBItem *item in setItems)
            if([item number] == -1)
            {
                WBItemType *itemType = [WBItemType itemTypeForTypeIdentifier_s:[item typeIdentifier]];
                if(![[itemType name] isEqualToString:@"?"])
                    [tempMissingItemTypes addObject:itemType];
            }
    }
    missingItemTypes = tempMissingItemTypes;
    [fetchingMissingItemTypes unlock];
    return missingItemTypes;
}

- (id)missingItemTypes:(void(^)(id result))asyncHandler
{
    if(missingItemTypes) return missingItemTypes;
    @synchronized(self)
    {
        if(![fetchingMissingItemTypes tryLock])
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [fetchingMissingItemTypes lock];
                [fetchingMissingItemTypes unlock];
                performBlockMainThread(asyncHandler, [self missingItemTypes_s]);
            });
            return nil; // Already fetching, return result when available
        }
    }
    
    [[[WBSession instance] asyncRequestQueue] addOperationWithBlock:^{
        performBlockMainThread(asyncHandler, [self missingItemTypes_s]);
    }];
    return nil;
}

- (NSArray *)recursiveMixForItem_s:(WBItemType *)itemType
{
    // Start with the actual mix:
    NSMutableArray *actualMix = [[itemType mix_s] mutableCopy];
    for(WBItemType *subMixType in [NSArray arrayWithArray:actualMix])
    {
        // Now add any sub mixes
        NSArray *subMixItems = [self recursiveMixForItem_s:subMixType];
        [actualMix addObjectsFromArray:subMixItems];
    }
    
    // And return the result
    return [NSArray arrayWithArray:actualMix];
}

- (id)comboItemsNeeded_s
{
    NSMutableArray *allMissingItemTypes = [self missingItemTypes_s];
    if(![allMissingItemTypes isKindOfClass:[NSMutableArray class]])
        return allMissingItemTypes; // Error
    NSMutableArray *tempComboItemsNeeded = [NSMutableArray array];
    for(WBItemType *missingItemType in allMissingItemTypes)
    {
        NSArray *recursiveMix = [self recursiveMixForItem_s:missingItemType];
        for(WBItemType *mixItemType in recursiveMix)
            if(![tempComboItemsNeeded containsObject:mixItemType])
                [tempComboItemsNeeded addObject:mixItemType];
    }
    comboItemsNeeded = tempComboItemsNeeded;
    return comboItemsNeeded;
}
                                
- (id)comboItemsNeeded:(void(^)(id result))asyncHandler
{
    NSOperationQueue *asyncQueue = [[WBSession instance] asyncRequestQueue];
    if(comboItemsNeeded) return comboItemsNeeded;
    @synchronized(self)
    {
        if(![fetchingComboItems tryLock]) // Only one combo item fetch at a time
        {
            [asyncQueue addOperationWithBlock:^{
                [fetchingComboItems lock];
                [fetchingComboItems unlock];
                performBlockMainThread(asyncHandler, [self comboItemsNeeded_s]);
            }];
            return nil;
        }
    }
    
    [asyncQueue addOperationWithBlock:^{
        performBlockMainThread(asyncHandler, [self comboItemsNeeded_s]);
        [fetchingComboItems unlock];
    }];
        
    return comboItemsNeeded;
}
@end
