//
//  MCLRouter.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;
@protocol MCLTheme;
@protocol MCLRouterDelegate;

@class MCLSplitViewController;

@class MCLProfileTableViewController;
@class MCLUser;

@interface MCLRouter : NSObject

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong) id<MCLRouterDelegate> delegate;
@property (strong, nonatomic) MCLSplitViewController *splitViewController;
@property (strong, nonatomic) UINavigationController *masterNavigationController;
@property (strong, nonatomic) UINavigationController *detailNavigationController;
@property (strong, nonatomic) UINavigationController *modalNavigationController;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;

- (void)launchRootWindow:(void (^)(UIWindow *window))windowHandler;
- (BOOL)modalIsPresented;
- (void)dismissModalIfPresentedWithCompletionHandler:(void (^)(BOOL dismissed))completionHandler;

@end
