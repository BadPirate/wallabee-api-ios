//
//  WBUser.m
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Good. All rights reserved.
//

#import "WBUser.h"
#import "WBSession.h"
#import "WBSet.h"
#import "WBItem.h"

@interface WBUser ()
@property (nonatomic, retain) NSDictionary *data;
@property (nonatomic, assign) NSInteger completedSets;
@property (nonatomic, retain) NSMutableArray *collectedItems, *sets;
@property (nonatomic, retain) NSLock *fetchingCollectedItems;
@end

@implementation WBUser
@synthesize data, completedSets, collectedItems, sets, fetchingCollectedItems;
- (id)initWithData:(NSDictionary *)dataDictionary
{
    self = [super init];
    self.data = dataDictionary;
    self.completedSets = -1; // Need to fetch data
    self.fetchingCollectedItems = [[NSLock alloc] init];
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

- (id)sets:(void(^)(id result))asyncHandler
{
    if(sets) return sets;
        
    NSOperationQueue *asyncRequestQueue = [[WBSession instance] asyncRequestQueue];
    
    [asyncRequestQueue addOperationWithBlock:^{
        NSString *requestString = [NSString stringWithFormat:@"/users/%@/sets",[self name_s]];
        NSDictionary *response = [WBSession makeSyncRequest:requestString];
        if(![response isKindOfClass:[NSDictionary class]])
        {
            asyncHandler(response);
            return; // Error
        }
        NSArray *setsArray = [response objectForKey:@"sets"];
        sets = [NSMutableArray arrayWithCapacity:[setsArray count]];
        
        for(NSDictionary *setDictionary in setsArray)
        {
            WBSet *set = [[WBSet alloc] initSetWithData:setDictionary user:self];
            [sets addObject:set];
        }
        
        completedSets = [[response objectForKey:@"completedSets"] intValue];
        
        asyncHandler(sets);
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

- (id)collectedItems:(void(^)(id result))asyncHandler
{
    @synchronized(self)
    {
        if(collectedItems) return collectedItems;
        collectedItems = [NSMutableArray array];
    }
    
    [fetchingCollectedItems lock];
    if([collectedItems count] > 0)
    {
        [fetchingCollectedItems unlock];
        return collectedItems;
    }

    NSArray *userSets = [self sets:^(id result) {
        [self parseCollectedItems:result asyncHandler:asyncHandler];
    }];
    if(userSets)
        return [self parseCollectedItems:userSets asyncHandler:asyncHandler];
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
@end
