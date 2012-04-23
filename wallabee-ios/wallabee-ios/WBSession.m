//
//  WBSession.m
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Good. All rights reserved.
//

#import "WBSession.h"

@interface WBSession ()
@property (nonatomic,retain) NSDate *lastRequest;
@property (nonatomic,retain) NSOperationQueue *asyncRequestQueue;
@property (nonatomic,retain) NSMutableArray *existingRequests;
@end

@implementation WBSession
@synthesize wallabeeAPIKey, lastRequest, asyncRequestQueue, maxRequestsPerSecond, existingRequests;
+ (NSString *)errorStringForResult:(id)result
{
    NSString *message = [result description];
    if([result isKindOfClass:[NSError class]])
    {
        NSDictionary *userInfo = [(NSError *)result userInfo];
        if([userInfo isKindOfClass:[NSDictionary class]] && 
           [userInfo objectForKey:@"error"])
            message = [[(NSError *)result userInfo] objectForKey:@"error"];
        else message = [(NSError *)result localizedDescription];
    }
    return message;
}

+ (WBSession *)instance
{
    static dispatch_once_t pred = 0;
    __strong static WBSession *_sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
        _sharedObject.maxRequestsPerSecond = 4;
        _sharedObject.existingRequests = [NSMutableArray arrayWithCapacity:_sharedObject.maxRequestsPerSecond];
        _sharedObject.asyncRequestQueue = [[NSOperationQueue alloc] init];
    });
    return _sharedObject;
}

+ (void)delayForCooldown
{
    WBSession *instance = [self instance];
    NSMutableArray *existingRequests = instance.existingRequests;
    
    @synchronized(existingRequests)
    {
        if([existingRequests count] >= instance.maxRequestsPerSecond)
        {
            NSDate *bottomRequest = [existingRequests objectAtIndex:0];
            NSTimeInterval timeSinceBottomRequest = -[bottomRequest timeIntervalSinceNow];
            if(timeSinceBottomRequest < 1)
            {
                // Wait until it expires...
                NSTimeInterval sleepPeriod = 1-timeSinceBottomRequest;
                [NSThread sleepForTimeInterval:sleepPeriod];
            }
            
            // Dump it
            [existingRequests removeObjectAtIndex:0];
        }
        // Add new request time to array
        [existingRequests addObject:[NSDate date]];
        return;
    }
}

+ (NSMutableURLRequest *)requestForPath:(NSString *)requestPath
{
    WBSession *instance = [self instance];
    NSString *wallabeeAPIKey = instance.wallabeeAPIKey;
    NSAssert(wallabeeAPIKey,@"APIKey required before making any API requests");
    
    NSString *URLString = [NSString stringWithFormat:@"http://api.wallab.ee%@",requestPath];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request addValue:wallabeeAPIKey forHTTPHeaderField:@"X-WallaBee-API-Key"];
    NSLog(@"Request - %@",URLString);
    return request;
}

+ (id)parseResponse:(NSURLResponse *)response error:(NSError *)error data:(NSData *)data
{
    if(error)
        return error;
    NSError *parsingError = nil;
    id parsedObject = [NSJSONSerialization JSONObjectWithData:data
                                                      options:kNilOptions
                                                        error:&parsingError];
    NSLog(@"Parse Response - %@",parsedObject);
    if(parsingError)
        return parsingError;
    if([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        switch ([httpResponse statusCode]) {
            case 200: // Success
            case 201: // Created
            case 204: // No Content
                return parsedObject;
            case 400:
            case 401:
            case 403:
            case 404:
            case 500:
            default:
            {
                NSError *error = [NSError errorWithDomain:@"WALLABEE" code:[httpResponse statusCode] userInfo:parsedObject];
                return error;
            }
        }
    }

    return parsedObject;
}

+ (void)makeAsyncRequest:(NSString *)requestPath result:(void(^)(id response))resultHandler
{
    WBSession *instance = [self instance];
    void(^copiedHandler)(id response) = [resultHandler copy]; // Copy because blocks in blocks can release
    
    [[instance asyncRequestQueue] addOperationWithBlock:^{
        copiedHandler([self makeSyncRequest:requestPath]); 
    }];
}

+ (id)makeSyncRequest:(NSString *)requestPath
{
    [self delayForCooldown];
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:[self requestForPath:requestPath]
                                           returningResponse:&response
                                                       error:&error];
    return [self parseResponse:response error:error data:data];
}
@end
