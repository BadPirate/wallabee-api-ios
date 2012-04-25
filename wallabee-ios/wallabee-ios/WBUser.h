//
//  WBUser.h
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Good. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WBUser : NSObject
// Synchronous call, returns a user object or NSError
+ (id)userWithName_s:(NSString *)userName;

// Sync / Async - If available without network access returns a NSMutableArray of WBSet objects, or NSError, otherwise returns nil, and later returns the result to the asyncHandler
- (id)sets:(void(^)(id result))asyncHandler;

// Synchronous - Returns NSString name or NSError
- (id)name_s;

// Returns User ID, no delay as this is always set on any initialized WBUser
- (NSInteger)userIdentifier;

// Sync / Async - If available without network access returns an NSArray of collected items, or NSError, otherwise returns nil, and later returns the result to the asyncHandler
- (id)collectedItems:(void(^)(id result))asyncHandler;

// Sync / Async - If available without network access returns an NSMutableDictionary of NSMutableArrays of WBItem objects grouped by type, or NSError, otherwise returns nil and later returns the result to asyncHandler
- (id)collectedItemsByType:(void(^)(id result))asyncHandler;

// Async - Refreshes the users collection, returns NSArray of collected items or NSError to asyncHandler
- (void)refreshCollection_a:(void(^)(id result))asyncHandler;
@end
