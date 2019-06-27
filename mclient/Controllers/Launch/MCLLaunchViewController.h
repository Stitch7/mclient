//
//  MCLLaunchViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;

@interface MCLLaunchViewController : UIViewController

@property (strong, nonatomic) UIView *loadingContainerView;

- (instancetype)initWithLaunchViewController:(UIViewController *)launchViewController;

@end
