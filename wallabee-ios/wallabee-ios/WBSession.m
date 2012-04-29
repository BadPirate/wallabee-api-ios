//
//  WBSession.m
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Good. All rights reserved.
//

#import "WBSession.h"

@interface WBSession ()
@property (nonatomic,retain) NSObject *cooldown;
@property (nonatomic,retain) NSMutableSet *pendingRequests;
@property (nonatomic,retain) NSLock *requestLock;
@end

@implementation WBSession
@synthesize wallabeeAPIKey, asyncRequestQueue, maxRequestsPerSecond, cooldown, cachedPlaces, pendingRequests, requestLock, cachedItemTypes;
+ (void)resetCache
{
    WBSession *session = [WBSession instance];
    session.cachedPlaces = nil;
}

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
        _sharedObject.maxRequestsPerSecond = 5;
        _sharedObject.asyncRequestQueue = [[NSOperationQueue alloc] init];
        _sharedObject.cooldown = [[NSObject alloc] init];
        _sharedObject.cachedPlaces = [NSMutableDictionary dictionary];
        _sharedObject.pendingRequests = [NSMutableSet setWithCapacity:_sharedObject.maxRequestsPerSecond];
        _sharedObject.requestLock = [[NSLock alloc] init];
        _sharedObject.cachedItemTypes = [NSMutableDictionary dictionary];
    });
    return _sharedObject;
}

+ (NSMutableURLRequest *)requestForPath:(NSString *)requestPath
{
    WBSession *instance = [self instance];
    NSString *wallabeeAPIKey = instance.wallabeeAPIKey;
    NSAssert(wallabeeAPIKey,@"APIKey required before making any API requests");
    
    NSString *URLString = [NSString stringWithFormat:@"http://api.wallab.ee%@",requestPath];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.timeoutInterval = 15;
    [request addValue:wallabeeAPIKey forHTTPHeaderField:@"X-WallaBee-API-Key"];
    NSLog(@"Granting Request... - %@",URLString);
    [[instance requestLock] lock];
    @synchronized([instance pendingRequests])
    {
        [[instance pendingRequests] addObject:request];
        NSLog(@"Request Granted - %@",URLString);
        if([[instance pendingRequests] count] < [instance maxRequestsPerSecond])
            [[instance requestLock] unlock];
    }
    return request;
}

- (void)delayedRequestRemoval:(NSMutableURLRequest *)request
{
    NSLog(@"Delayed Request Removal");
    @synchronized(pendingRequests)
    {
        [pendingRequests removeObject:request];
        if([pendingRequests count] == maxRequestsPerSecond-1)
            [requestLock unlock];
    }
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
    
    [[instance asyncRequestQueue] addOperationWithBlock:^{
        resultHandler([self makeSyncRequest:requestPath]); 
    }];
}

+ (id)makeSyncRequest:(NSString *)requestPath
{
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSMutableURLRequest *request = [self requestForPath:requestPath];
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                           returningResponse:&response
                                                       error:&error];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[WBSession instance] performSelector:@selector(delayedRequestRemoval:) withObject:request afterDelay:1];
    });
    return [self parseResponse:response error:error data:data];
}

void performBlockMainThread(void(^asyncBlock)(id response), id result)
{
    if([NSThread currentThread] != [NSThread mainThread])
        dispatch_async(dispatch_get_main_queue(), ^{
            asyncBlock(result);
        });
    else asyncBlock(result);
}

@end
