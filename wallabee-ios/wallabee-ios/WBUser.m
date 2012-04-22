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

@interface WBUser ()
@property (nonatomic, retain) NSDictionary *data;
@property (nonatomic, assign) NSInteger completedSets;
@property (nonatomic, assign) NSUInteger userIdentifier;
@property (nonatomic, retain) NSMutableArray *collectedItems, *sets;
@end

@implementation WBUser
@synthesize data, completedSets, userIdentifier, collectedItems, sets;
- (id)initWithData:(NSDictionary *)dataDictionary
{
    self = [super init];
    self.data = dataDictionary;
    self.completedSets = -1; // Need to fetch data
    self.userIdentifier = [[dataDictionary objectForKey:@"id"] intValue];
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

- (NSUInteger)identifier
{
    return userIdentifier;
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
@end
