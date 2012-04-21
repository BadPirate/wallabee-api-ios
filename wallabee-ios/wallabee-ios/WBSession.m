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
@property (nonatomic,retain) NSLock *coolDownLock;
@property (nonatomic,retain) NSOperationQueue *asyncRequestQueue;
@end

@implementation WBSession
@synthesize maxRequestRate, wallabeeAPIKey, lastRequest, coolDownLock, asyncRequestQueue;

+ (WBSession *)instance
{
    static dispatch_once_t pred = 0;
    __strong static WBSession *_sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
        [_sharedObject setMaxRequestRate:0.25];
        _sharedObject.coolDownLock = [[NSLock alloc] init];
        _sharedObject.asyncRequestQueue = [[NSOperationQueue alloc] init];
    });
    return _sharedObject;
}

+ (void)delayForCooldown
{
    WBSession *instance = [self instance];
    NSLock *coolDownLock = instance.coolDownLock;
    [coolDownLock lock]; // Handle only one cooldown request at a time, thread safety
    if(!instance.lastRequest)
    {
        instance.lastRequest = [NSDate date];
        [coolDownLock unlock];
        return;
    }
    
    NSTimeInterval timeSinceLastRequest = -[instance.lastRequest timeIntervalSinceNow];
    if(timeSinceLastRequest < instance.maxRequestRate)
    {
        NSTimeInterval sleepPeriod = instance.maxRequestRate-timeSinceLastRequest;
        [NSThread sleepForTimeInterval:sleepPeriod];
    }
    instance.lastRequest = [NSDate date];
    [coolDownLock unlock];
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
    if(parsingError)
        return parsingError;
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
