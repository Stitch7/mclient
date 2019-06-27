//
//  MCLUserSearchDelegate.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLUserSearchViewController;
@class MCLUser;

@protocol MCLUserSearchDelegate <NSObject>

- (void)userSearchViewController:(MCLUserSearchViewController *)userSearchViewController didPickUser:(MCLUser *)user;

@end
