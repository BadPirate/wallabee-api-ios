//
//  WBItem.m
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Logic High Software All rights reserved.
//

#import "WBItem.h"
#import "WBUser.h"
#import "WBSet.h"
#import "WBSession.h"
#import "WBItemType.h"

@interface WBItem ()
@property (nonatomic,retain) NSMutableArray *fetchingImageArray;
@property (nonatomic,retain) NSDictionary *data;
@end

@implementation WBItem
@synthesize data,user,place,set,fetchingImageArray;

- (id)initWithDictionary:(NSDictionary *)dataDictionary
{
    self = [super init];
    data = dataDictionary;
    fetchingImageArray = [NSMutableArray array];
    return self;
}

- (BOOL)isCollected
{
    return ([[data objectForKey:@"number"] length] > 0);
}

- (NSString *)name
{
    return [data objectForKey:@"name"];
}

- (NSInteger)number
{
    NSString *number = [data objectForKey:@"number"];
    if(![number isKindOfClass:[NSString class]] || [number isEqualToString:@""])
        return -1;
    return [number intValue];
}

- (NSInteger)itemIdentifier
{
    if([data objectForKey:@"item_id"])
        return [[data objectForKey:@"item_id"] intValue];
    return -1;
}

- (NSInteger)typeIdentifier
{
    if([data objectForKey:@"item_type_id"])
        return [[data objectForKey:@"item_type_id"] intValue];
    if([data objectForKey:@"id"])
        return [[data objectForKey:@"id"] intValue];
    return -1;    
}

- (UIImage *)imageWithWidth:(NSInteger)widthInPixels retina:(BOOL)retinaImage result:(void(^)(id result))resultBlock
{
    NSString *requestString = [NSString stringWithFormat:@"http://api.wallab.ee/image/item-%d-%d",
                               [self typeIdentifier],widthInPixels];  
    NSURL *URL = [NSURL URLWithString:requestString];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL cachePolicy:NSURLCacheStorageAllowed timeoutInterval:30];
    NSCachedURLResponse *response = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    if(response)
    {
        UIImage *image = [UIImage imageWithData:[response data]];
        if(retinaImage)
            image = [UIImage imageWithCGImage:image.CGImage scale:2 orientation:image.imageOrientation];
        return image;
    }
    
    // No response, we have to load it.
    // First, lets make sure that only 1 load is attempted at a time.
    NSNumber *widthIdentifier = nil;
    @synchronized(self)
    {
        for(NSNumber *loadingWidth in fetchingImageArray)
            if([loadingWidth intValue] == widthInPixels)
            {
                widthIdentifier = loadingWidth;
                break;
            }
        if(!widthIdentifier)
        {
            widthIdentifier = [NSNumber numberWithInt:widthInPixels];
            [fetchingImageArray addObject:widthIdentifier];
        }
    }
    
    @synchronized(widthIdentifier)
    {
        // Check again for existing request
        response = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
        if(response)
        {
            UIImage *image = [UIImage imageWithData:[response data]];
            if(retinaImage)
                image = [UIImage imageWithCGImage:image.CGImage scale:2 orientation:image.imageOrientation];
            return image;
        }
        
        // Okay, this must be the first time then... go and get it!
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSURLResponse *response = nil;
            NSError *error = nil;
            NSData *imageData = [NSURLConnection sendSynchronousRequest:request
                                                      returningResponse:&response
                                                                  error:&error];
            if(error)
            {
                performBlockMainThread(resultBlock, error);
                return;
            }
            [fetchingImageArray removeObject:widthIdentifier];
            UIImage *image = [UIImage imageWithData:imageData];
            if(retinaImage)
                image = [UIImage imageWithCGImage:image.CGImage scale:2 orientation:image.imageOrientation];
            if(!image)
            {
                performBlockMainThread(resultBlock, [NSError errorWithDomain:@"WALLABEE" code:[(NSHTTPURLResponse *)response statusCode] userInfo:nil]);
                return;
            }
            performBlockMainThread(resultBlock, image);
        });
        return nil; // Nil gets returned if we are loading (for sync)
    }
}

- (id)parseNumberImprovementForUser:(WBUser *)userChosen collectedItems:(NSMutableDictionary *)collectedItemsByType
{
    if(![collectedItemsByType isKindOfClass:[NSMutableDictionary class]])
        return collectedItemsByType;
    NSMutableArray *collectedItemsForType = [collectedItemsByType objectForKey:[NSString stringWithFormat:@"%d",[self typeIdentifier]]];
    if(!collectedItemsForType) return [NSNumber numberWithBool:YES];
    NSInteger improvement = [self number];
    for(WBItem *item in collectedItemsForType)
        if([item number] < [self number])
        {
            return [NSNumber numberWithInt:-1];
        }
        else {
            improvement = [item number] - [self number];
        }
    return [NSNumber numberWithInt:improvement];
}

- (id)numberImprovementForUser:(WBUser *)userChosen handler:(void(^)(id result))asyncHandler
{    
    NSMutableDictionary *collectedItemsByType = [userChosen collectedItemsByType:^(id result) {
        asyncHandler([self parseNumberImprovementForUser:userChosen collectedItems:result]);
    }];
    if(collectedItemsByType)
        return [self parseNumberImprovementForUser:userChosen collectedItems:collectedItemsByType];
    return nil; // Async
}

- (id)parseUserHasItemLikeThis:(NSMutableDictionary *)collectedItemsByType user:(WBUser *)userChosen
{
    if(![collectedItemsByType isKindOfClass:[NSMutableDictionary class]])
        return collectedItemsByType;
    NSMutableArray *collectedItemsForType = [collectedItemsByType objectForKey:[NSString stringWithFormat:@"%d",[self typeIdentifier]]];
    if(!collectedItemsForType) return [NSNumber numberWithBool:NO];
    return [NSNumber numberWithBool:YES];
}

- (id)userHasItemLikeThis:(WBUser *)userChosen handler:(void(^)(id result))asyncHandler
{    
    NSMutableDictionary *collectedItemsByType = [userChosen collectedItemsByType:^(id result) {
        asyncHandler([self parseUserHasItemLikeThis:result user:userChosen]);
    }];
    if(collectedItemsByType)
        return [self parseUserHasItemLikeThis:collectedItemsByType user:userChosen];
    return nil;
}

- (id)parseComboItemsNeeded:(NSArray *)comboItemsNeeded
{
    if(!comboItemsNeeded) return nil; // Async
    if(![comboItemsNeeded isKindOfClass:[NSArray class]])
        return comboItemsNeeded; // Error
    for(WBItemType *neededItemType in comboItemsNeeded)
        if([neededItemType typeIdentifier] == [self typeIdentifier])
            return [NSNumber numberWithBool:YES];
    return [NSNumber numberWithBool:NO];
}

- (id)userNeedsForCombo:(WBUser *)userPassed handler:(void(^)(id result))asyncHandler
{
    NSMutableArray *comboItemsNeeded = [userPassed comboItemsNeeded:^(id result) {
        performBlockMainThread(asyncHandler, [self parseComboItemsNeeded:result]);
    }];
    return [self parseComboItemsNeeded:comboItemsNeeded];
}

- (WBItemType *)itemType_s
{
    return [WBItemType itemTypeForTypeIdentifier_s:[self typeIdentifier]];
}
@end
