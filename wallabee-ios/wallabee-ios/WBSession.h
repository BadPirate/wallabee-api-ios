//
//  WBSession.h
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Good. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WBSession : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
// API Key, must be set prior to API usage
@property (nonatomic,retain) NSString *wallabeeAPIKey;

// Maximum Request rate in seconds, default .25 (4 times per second)
@property (nonatomic,assign) NSTimeInterval maxRequestRate;

// Returns the shared instance of WBSession (WBSession is a singleton)
+ (WBSession *)instance;

// Returns a response object, could be NSDictionary, NSArray or NSError, runs synchronously
+ (id)makeSyncRequest:(NSString *)requestPath;

// Returns a response object (same as makeSyncRequest), however runs asynchronously, and performs
// Response handler when the request is completed.
+ (void)makeAsyncRequest:(NSString *)request result:(void(^)(id response))resultHandler;
@end
