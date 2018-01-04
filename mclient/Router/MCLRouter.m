//
//  MCLRouter.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRouter.h"

#import "MCLDependencyBag.h"
#import "MCLRouterDelegate.h"
#import "MCLLogin.h"
#import "MCLThemeManager.h"
#import "MCLSplitViewController.h"
#import "MCLDetailNavigationController.h"


@interface MCLRouter () <UISplitViewControllerDelegate>

@end

@implementation MCLRouter

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;

    return self;
}

#pragma mark - Configuration

- (void)configure
{
    self.splitViewViewController = [[MCLSplitViewController alloc] initWithBag:self.bag];
    self.masterViewController = [self.delegate createMasterViewControllerForRouter:self];
    self.masterNavigationController = [[UINavigationController alloc] initWithRootViewController:self.masterViewController];
    self.detailViewController = [self.delegate createDetailViewControllerForRouter:self];
    self.detailNavigationController = [[MCLDetailNavigationController alloc] initWithBag:self.bag
                                                                      rootViewController:self.detailViewController];

    NSMutableArray *splitViews = [[NSMutableArray alloc] init];
    [splitViews addObject:self.masterNavigationController];
    [splitViews addObject:self.detailNavigationController];
    self.splitViewViewController.viewControllers = splitViews;
    self.splitViewViewController.delegate = self;
    
    if (!self.splitViewViewController.isCollapsed) {
        self.splitViewViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    }
}


#pragma mark - UISplitViewControllerDelegate

- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController
{
    return [self.delegate handleSplitViewCollapsingForRouter:self];
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
    return YES;
}

- (UIViewController *)primaryViewControllerForExpandingSplitViewController:(UISplitViewController *)splitViewController;
{
    return nil;
}

- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController
{
    return [self.delegate handleSplitViewSeparatingForRouter:self];
}

#pragma mark - Public Methods

- (UIWindow *)makeRootWindowWithDelegate:(id<MCLRouterDelegate>)delegate
{
    self.delegate = delegate;
    [self configure];
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.rootViewController = self.splitViewViewController;
    [window makeKeyAndVisible];

    self.rootWindow = window;

    return window;
}

@end
