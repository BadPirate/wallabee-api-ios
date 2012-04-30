//
//  WBItemType.m
//  PirateWalla
//
//  Created by Kevin Lohman on 4/29/12.
//  Copyright (c) 2012 Logic High Software All rights reserved.
//

#import "WBItemType.h"
#import "WBSession.h"

@interface WBItemType ()
- (id)initWithTypeIdentifier:(NSInteger)typeIdentifierGiven;
- (NSDictionary *)loadData_s;
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

- (void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    [encoder encodeObject:data forKey:@"data"];
    [encoder encodeObject:mix forKey:@"mix"];
    [encoder encodeObject:[NSNumber numberWithInt:typeIdentifier] forKey:@"typeIdentifier"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        //decode properties, other class vars
        self.data = [decoder decodeObjectForKey:@"data"];
        self.mix = [decoder decodeObjectForKey:@"mix"];
        self.typeIdentifier = [[decoder decodeObjectForKey:@"typeIdentifier"] intValue];
    }
    return self;
}

+ (id)itemTypeForTypeIdentifier_s:(NSInteger)typeIdentifierGiven
{
    NSMutableDictionary *cachedItemTypes = [[WBSession instance] cachedItemTypes];
    NSString *typeIdentifierString = [NSString stringWithFormat:@"%d",typeIdentifierGiven];
    WBItemType *cachedItemType = [cachedItemTypes objectForKey:typeIdentifierString];
    if(cachedItemType)
        return cachedItemType;
    cachedItemType = [[self alloc] initWithTypeIdentifier:typeIdentifierGiven];
    [cachedItemType loadData_s];
    if(cachedItemType.data)
        [WBSession saveCache]; // Item types don't change very often, store this so that you won't have to do it next time.
    [cachedItemTypes setObject:cachedItemType forKey:typeIdentifierString];
    return cachedItemType;
}

- (NSInteger)typeIdentifier
{
    return typeIdentifier;
}

- (NSDictionary *)loadData_s
{
    if(data) return data;
    @synchronized(self)
    {
        if(![fetchingData tryLock])
        {
            [fetchingData lock];
            [fetchingData unlock];
            return data;
        }
    }
    
    NSString *requestString = [NSString stringWithFormat:@"/itemtypes/%d",[self typeIdentifier]];
    id result = [WBSession makeSyncRequest:requestString];
    if([result isKindOfClass:[NSDictionary class]])
    {
        data = result;
    }
    
    [fetchingData unlock];
    return result;
}

- (id)parseMix_s:(NSArray *)mixArray
{
    if(![mixArray isKindOfClass:[NSArray class]])
        return mixArray;
    NSMutableArray *mixItemTypeArray = [NSMutableArray arrayWithCapacity:[mixArray count]];
    for(NSString *typeIdentifierString in mixArray)
        [mixItemTypeArray addObject:[WBItemType itemTypeForTypeIdentifier_s:[typeIdentifierString intValue]]];
    mix = mixItemTypeArray;
    return [NSArray arrayWithArray:mix];
}

- (id)mix_s
{
    if(mix) return mix;
    return [self parseMix_s:[data objectForKey:@"mix"]];
}

- (id)name
{
    return [data objectForKey:@"name"];
}

@end
