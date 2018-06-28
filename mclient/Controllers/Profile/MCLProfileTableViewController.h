//
//  MCLProfileTableViewController.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoadingViewControllerDelegate.h"

@protocol MCLDependencyBag;
@class MCLUser;

@interface MCLProfileTableViewController : UITableViewController <MCLLoadingViewControllerDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) MCLUser *user;

@property (strong, nonatomic) NSMutableDictionary *profileData;
@property (strong, nonatomic) NSArray *profileKeys;

@end
