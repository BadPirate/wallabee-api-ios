//
//  WBItem.h
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Good. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WBSet, WBUser, WBPlace;

@interface WBItem : NSObject
@property (nonatomic,retain) WBPlace *place;
@property (nonatomic,retain) WBUser *user;
@property (nonatomic,retain) WBSet *set;

// Creates a new WBItem object from a data dictionary, set and user optional, but should be provided if available.
- (id)initWithDictionary:(NSDictionary *)dataDictionary;

// Returns yes if this is a collected user item, no if it is not.
- (BOOL)isCollected;

// Returns the name of the object
- (NSString *)name;

// Returns the number (ranking) of an item, -1 if they don't have it
- (NSInteger)number;

// Returns the identifier of the item, -1 if it can't be determined
- (NSInteger)itemIdentifier;

// Returns the item type identifier, -1 if it can't be determined
- (NSInteger)typeIdentifier;

// Async / sync - If cached image is available, returns UIImage immediately, otherwise Calls result block with either UIImage or NSError when image is loaded, and returns nil initially
- (UIImage *)imageWithWidth:(NSInteger)widthInPixels retina:(BOOL)retinaImage result:(void(^)(id result))resultBlock;

// Async / Sync - returns [NSNumber] with the delta for item improvement if this is the lower then the item the user has collected of this type, [NSNumber] with -1 if not, or NSError if available immediately, otherwise returns nil and later calls asyncHandler
- (id)numberImprovementForUser:(WBUser *)user handler:(void(^)(id result))asyncHandler;

// Async / Sync - Returns [NSNumber bool] YES if the user has an item of this type, NO if not, or NSError, if requires a connection, returns nil, and later returns the result to asyncHandler
- (id)userHasItemLikeThis:(WBUser *)user handler:(void(^)(id result))asyncHandler;
@end
