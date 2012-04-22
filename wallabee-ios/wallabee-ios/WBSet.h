//
//  WBSet.h
//  wallabee-ios
//
//  Created by Kevin Lohman on 4/21/12.
//  Copyright (c) 2012 Good. All rights reserved.
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

// Returns a NSMutableArray of WBItem objects, or NSError
- (id)items_s;

// Returns a list of the collected WBItem objects, or NSError
- (id)collectedItems_s;

// Returns the identifier of the set
- (NSInteger)setIdentifier;
@end
