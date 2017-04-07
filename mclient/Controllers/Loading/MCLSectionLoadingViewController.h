//
//  MCLSectionLoadingViewController.h
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoadingViewController.h"

@protocol MCLDependencyBag;
@protocol MCLLoadingViewControllerDelegate;
@protocol MCLRequest;

@interface MCLSectionLoadingViewController : UIViewController

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (weak) id<MCLLoadingViewControllerDelegate> delegate;
@property (strong, nonatomic) UIViewController *contentViewController;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag requests:(NSArray<__kindof id<MCLRequest>> *)requests forViewController:(UIViewController *)viewController;

- (void)load;
- (void)updateTitle;

@end
