//
//  WBSet.h
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Logic High Software All rights reserved.
//

#import <UIKit/UIKit.h>
@class WBUser;

@interface WBSet : NSObject
{
    @private
    BOOL _isUserSet;
}
@property (nonatomic, readonly) BOOL isUserSet;

// Init method, pass dictionary straight from any other method, user can be nil if the set is not a user set.
- (id)initSetWithData:(NSDictionary *)dataDictionary user:(WBUser *)user;

// Sync / Async, if availalbe without network connection Returns a NSMutableArray of WBItem objects, or NSError, otherwise returns nil and later calls handler with result.
- (id)items:(void(^)(id result))asyncHandler;

// Sync - Returns NSMutableArray of WBItem objects or NSError, note could block thread for network
- (id)items_s;

// Sync / Async, if available without network Returns a list of the collected WBItem objects, or NSError, otherwise returns nil, and later calls handler with the WBItem objects or NSError result.
- (id)collectedItems:(void(^)(id result))asyncHandler;

// Returns the identifier of the set
- (NSInteger)setIdentifier;
@end
