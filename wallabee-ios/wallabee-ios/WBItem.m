//
//  WBItem.m
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Good. All rights reserved.
//

#import "WBItem.h"
#import "WBUser.h"
#import "WBSet.h"

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
    return [[data objectForKey:@"number"] intValue];
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
        void(^resultBlockCopy)(id result) = [resultBlock copy]; // Block in a block
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSURLResponse *response = nil;
            NSError *error = nil;
            NSData *imageData = [NSURLConnection sendSynchronousRequest:request
                                                      returningResponse:&response
                                                                  error:&error];
            if(error)
            {
                resultBlockCopy(error);
                return;
            }
            [fetchingImageArray removeObject:widthIdentifier];
            UIImage *image = [UIImage imageWithData:imageData];
            if(retinaImage)
                image = [UIImage imageWithCGImage:image.CGImage scale:2 orientation:image.imageOrientation];
            if(!image)
            {
                resultBlockCopy([NSError errorWithDomain:@"WALLABEE" code:[(NSHTTPURLResponse *)response statusCode]
                                                userInfo:nil]);
                return;
            }
            resultBlockCopy(image);
        });
        return nil; // Nil gets returned if we are loading (for sync)
    }
}

- (id)isLowestItemNumberForUser_s:(WBUser *)userChosen
{
    NSMutableDictionary *collectedItemsByType = [userChosen collectedItemsByType_s];
    if(![collectedItemsByType isKindOfClass:[NSMutableDictionary class]])
        return collectedItemsByType;
    NSMutableArray *collectedItemsForType = [collectedItemsByType objectForKey:[NSString stringWithFormat:@"%d",[self typeIdentifier]]];
    if(!collectedItemsForType) return [NSNumber numberWithBool:YES];
    for(WBItem *item in collectedItemsForType)
        if([item number] < [self number])
            return [NSNumber numberWithBool:NO];
    return [NSNumber numberWithBool:YES];
}

- (id)userHasItemLikeThis_s:(WBUser *)userChosen
{
    NSMutableDictionary *collectedItemsByType = [userChosen collectedItemsByType_s];
    if(![collectedItemsByType isKindOfClass:[NSMutableDictionary class]])
        return collectedItemsByType;
    NSMutableArray *collectedItemsForType = [collectedItemsByType objectForKey:[NSString stringWithFormat:@"%d",[self typeIdentifier]]];
    if(!collectedItemsForType) return [NSNumber numberWithBool:NO];
    return [NSNumber numberWithBool:YES];
}
@end
