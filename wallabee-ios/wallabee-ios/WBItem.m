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
@property (nonatomic,retain) NSDictionary *data;
@end

@implementation WBItem
@synthesize data;

- (id)initWithDictionary:(NSDictionary *)dataDictionary set:(WBSet *)set user:(WBUser *)user
{
    self = [super init];
    data = dataDictionary;
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

- (NSInteger)identifier
{
    if([data objectForKey:@"item_id"])
        return [[data objectForKey:@"item_id"] intValue];
    return -1;
}

- (NSInteger)typeIdentifier
{
    if([data objectForKey:@"item_type_id"])
        return [[data objectForKey:@"item_type_id"] intValue];
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
        return [UIImage imageWithData:[response data]];
    
    // No response, we have to load it.
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
@end
