//
//  WBSession.h
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Logic High Software All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WBSession : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
// Place cache -- To reset, remove all objects
@property (nonatomic, retain) NSMutableDictionary *cachedPlaces, *cachedItemTypes;

// For making requests in the background, used by other WBClasses
@property (nonatomic,retain) NSOperationQueue *asyncRequestQueue;

// API Key, must be set prior to API usage
@property (nonatomic,retain) NSString *wallabeeAPIKey;

// Maximum Request rate in seconds, default .25 (4 times per second)
@property (nonatomic,assign) NSUInteger maxRequestsPerSecond;

// Returns the shared instance of WBSession (WBSession is a singleton)
+ (WBSession *)instance;

// Returns a response object, could be NSDictionary, NSArray or NSError, runs synchronously
+ (id)makeSyncRequest:(NSString *)requestPath;

// Returns a response object (same as makeSyncRequest), however runs asynchronously, and performs
// Response handler when the request is completed.
+ (void)makeAsyncRequest:(NSString *)request result:(void(^)(id response))resultHandler;

+ (NSString *)errorStringForResult:(id)result;

// Resets the less permanent caches
+ (void)resetCache;

// Saves any cached item types to "WBCachedItemTypes" in NSUserDefaults (they don't change much), which will reduce the time it takes to do a number of calls
+ (void)saveCache;

void performBlockMainThread(void(^asyncBlock)(id response), id result);
@end
