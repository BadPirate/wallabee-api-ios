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
@property (nonatomic,assign) NSUInteger identifier;
@end

@implementation WBSet
@synthesize data, user, items, identifier;

- (id)initSetWithData:(NSDictionary *)dataDictionary user:(WBUser *)userPassed
{
    self = [super init];
    data = dataDictionary;
    identifier = [[dataDictionary objectForKey:@"id"] intValue];
    user = userPassed;
    return self;
}

- (BOOL)isUserSet
{
    if(user)
        return YES;
    return NO;
}

- (NSUInteger)identifier
{
    return identifier;
}

- (id)items_s
{
    if(items) return items;
    if([self isUserSet])
    {
        NSString *requestString = [NSString stringWithFormat:@"/users/%u/sets/%u",[user identifier],[self identifier]];
        NSDictionary *result = [WBSession makeSyncRequest:requestString];
        if(![result isKindOfClass:[NSDictionary class]])
            return result;
        NSArray *itemsArray = [result objectForKey:@"items"];
        items = [NSMutableArray arrayWithCapacity:[itemsArray count]];
        for(NSDictionary *itemDictionary in itemsArray)
        {
            WBItem *item = [[WBItem alloc] initWithDictionary:itemDictionary set:self user:user];
            [items addObject:item];
        }
        return items;
    }
    
    return nil; // TODO: Make work for non-user sets
}

- (id)collectedItems_s
{
    NSArray *allItems = [self items_s];
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
@end
