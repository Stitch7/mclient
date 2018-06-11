//
//  MCLSectionLoadingViewController.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoadingViewController.h"

@protocol MCLDependencyBag;
@protocol MCLSectionLoadingViewControllerDelegate;
@protocol MCLRequest;

@interface MCLSectionLoadingViewController : UIViewController

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (weak) id<MCLSectionLoadingViewControllerDelegate> delegate;
@property (strong, nonatomic) UIViewController *contentViewController;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag requests:(NSDictionary *)requests forViewController:(UIViewController *)viewController;

- (void)configureNotifications;

- (void)load;
- (void)updateTitle;

@end
