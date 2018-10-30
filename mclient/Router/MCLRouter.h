//
//  MCLRouter.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;
@protocol MCLTheme;
@protocol MCLRouterDelegate;

@class MCLSplitViewController;

@interface MCLRouter : NSObject

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong) id<MCLRouterDelegate> delegate;
@property (weak, nonatomic) UIWindow *rootWindow;
@property (strong, nonatomic) MCLSplitViewController *splitViewController;
@property (strong, nonatomic) UINavigationController *masterNavigationController;
@property (strong, nonatomic) UINavigationController *detailNavigationController;
@property (strong, nonatomic) UINavigationController *modalNavigationController;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;

- (UIWindow *)makeLaunchWindow;
- (UIWindow *)makeTerminationWindow;
- (UIWindow *)makeRootWindow;
- (void)replaceRootWindow:(UIWindow *)newWindow;
- (void)dismissModalIfPresentedWithCompletionHandler:(void (^)(BOOL dismissed))completionHandler;

@end
