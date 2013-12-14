//
//  WBItemType.h
//  PirateWalla
//
//  Created by Kevin Lohman on 4/29/12.
//  Copyright (c) 2012 Logic High Software All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WBItemType : NSObject
// Sync - Note that this could block thread for a moment before returning, use on background thread. Returns a shared instance of WBItemType for typeIdentifier
+ (id)itemTypeForTypeIdentifier_s:(NSInteger)typeIdentifier;

// Type Identifier - Returns type identifier
- (NSInteger)typeIdentifier;

// Sync - Returns NSMutableArray of WBItemType objects that can be used to mix, empty if there is no mix, NSError if error
- (id)mix_s;

// Returns NSString name for itemType
- (id)name;

// Sync - Returns NSMutableArray of WBItemType objects that this item type mixes to make or NSError, only uses cached WBItemType objects as source, so may be incomplete
- (id)makes_s;
@end
