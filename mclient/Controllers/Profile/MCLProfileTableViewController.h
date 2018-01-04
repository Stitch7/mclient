//
//  MCLProfileTableViewController.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoadingViewControllerDelegate.h"

@protocol MCLDependencyBag;
@protocol MCLProfileTableViewControllerDelegate;
@class MCLUser;

@interface MCLProfileTableViewController : UITableViewController <MCLLoadingViewControllerDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (weak) id<MCLProfileTableViewControllerDelegate> delegate;
@property (strong, nonatomic) MCLUser *user;

@property (strong, nonatomic) NSMutableDictionary *profileData;
@property (strong, nonatomic) NSArray *profileKeys;

@end

@protocol MCLProfileTableViewControllerDelegate <NSObject>

@optional
- (void)handleRotationChangeInBackground;

@end
