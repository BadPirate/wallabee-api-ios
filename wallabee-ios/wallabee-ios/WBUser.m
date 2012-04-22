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
@property (nonatomic, retain) NSMutableDictionary *collectedItemsByType;
@end

@implementation WBUser
@synthesize data, completedSets, collectedItems, collectedItemsByType, sets;
- (id)initWithData:(NSDictionary *)dataDictionary
{
    self = [super init];
    self.data = dataDictionary;
    self.completedSets = -1; // Need to fetch data
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
        return response; // Error
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

- (NSInteger)userIdentifier
{
    return [[data objectForKey:@"id"] intValue];
}

- (id)collectedItems_s
{
    if(collectedItems) return collectedItems;
    NSArray *userSets = [self sets_s];
    if(![userSets isKindOfClass:[NSArray class]])
        return userSets; // Error
    collectedItems = [NSMutableArray array];
    for(WBSet *set in userSets)
    {
        NSArray *collectedItemsForSet = [set collectedItems_s];
        if(![collectedItemsForSet isKindOfClass:[NSArray class]])
            return collectedItemsForSet;
        [collectedItems addObjectsFromArray:collectedItemsForSet];
    }
    return collectedItems;
}

- (id)collectedItemsByType_s
{
    NSMutableArray *allCollectedItems = [self collectedItems_s];
    if(![allCollectedItems isKindOfClass:[NSMutableArray class]])
        return allCollectedItems;
    if([allCollectedItems count] == 0)
        return allCollectedItems;
    @synchronized(self)
    {
        if(!collectedItemsByType)
            collectedItemsByType = [NSMutableDictionary dictionary];
    }
    @synchronized(collectedItemsByType)
    {
        if([collectedItemsByType count] > 0)
            return collectedItemsByType;
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
}
@end
