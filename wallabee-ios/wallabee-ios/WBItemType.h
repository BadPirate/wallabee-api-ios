//
//  WBItemType.h
//  PirateWalla
//
//  Created by Kevin Lohman on 4/29/12.
//  Copyright (c) 2012 Good. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WBItemType : NSObject
// Returns a shared instance of WBItemType for typeIdentifier
+ (id)itemTypeForTypeIdentifier:(NSInteger)typeIdentifier;

// Type Identifier - Returns type identifier
- (NSInteger)typeIdentifier;

// Sync / Async - Returns NSMutableArray of WBItemType objects that can be used to mix, empty if there is no mix, NSError if error, or nil if network access was required (later returning the result to the AsyncHandler)
- (id)mix:(void(^)(id result))asyncHandler;

// Sync / Async - Returns NSString for the items name, NSError if error, or nil if it will return to asyncHandler
- (id)name:(void(^)(id result))asyncHandler;
@end
