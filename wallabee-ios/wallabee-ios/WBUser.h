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

// Synchronous call, returns a NSMutableArray of WBSet objects, or NSError
- (id)sets_s;

// Synchronous - Returns NSString name or NSError
- (id)name_s;

// Returns User ID, no delay as this is always set on any initialized WBUser
- (NSInteger)userIdentifier;

// Synchronous - Returns an NSArray of uncollected items, or NSError
- (id)collectedItems_s;

// Synchronous - Returns an NSMutableDictionary of NSMutableArrays of WBItem objects grouped by type, or NSError
- (id)collectedItemsByType_s;
@end
