//
//  WBItem.h
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Good. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WBSet, WBUser;

@interface WBItem : NSObject
// Creates a new WBItem object from a data dictionary, set and user optional, but should be provided if available.
- (id)initWithDictionary:(NSDictionary *)dataDictionary set:(WBSet *)set user:(WBUser *)user;

// Returns yes if this is a collected user item, no if it is not.
- (BOOL)isCollected;

// Returns the name of the object
- (NSString *)name;

// Returns the number (ranking) of an item
- (NSInteger)number;

// Returns the identifier of the item, -1 if it can't be determined
- (NSInteger)identifier;

// Returns the item type identifier, -1 if it can't be determined
- (NSInteger)typeIdentifier;

// Async / sync - If cached image is available, returns UIImage immediately, otherwise Calls result block with either UIImage or NSError when image is loaded, and returns nil initially
- (UIImage *)imageWithWidth:(NSInteger)width result:(void(^)(id result))resultBlock;
@end
