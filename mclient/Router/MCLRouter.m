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
#import "MCLLaunchViewController.h"
#import "MCLDetailNavigationController.h"


@interface MCLRouter () <UISplitViewControllerDelegate>

@property (assign, nonatomic) BOOL alreadyConfigured;

@end

@implementation MCLRouter

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super init];
    if (!self) return nil;

    self.alreadyConfigured = NO;
    self.bag = bag;

    return self;
}

#pragma mark - Configuration

- (void)configureIfNecessary
{
    if (!self.alreadyConfigured) {
        [self configure];
        self.alreadyConfigured = YES;
    }
}

- (void)configure
{
    assert(self.delegate != nil);
    
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

#pragma mark - Private Helper

- (UIWindow *)makeWindowWithViewController:(UIViewController *)rootViewController
{
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.rootViewController = rootViewController;
    [window makeKeyAndVisible];

    self.rootWindow = window;

    return window;
}

#pragma mark - Public Methods

- (UIWindow *)makeLaunchWindow
{
    [self configureIfNecessary];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LaunchScreen" bundle:nil];
    UIViewController *storyboardLaunchVC = [storyboard instantiateViewControllerWithIdentifier:@"MCLLaunchViewController"];
    MCLLaunchViewController *launchVC = [[MCLLaunchViewController alloc] initWithLaunchViewController:storyboardLaunchVC];

    return [self makeWindowWithViewController:launchVC];
}

- (UIWindow *)makeRootWindow
{
    [self configureIfNecessary];
    self.rootWindow = [self makeWindowWithViewController:self.splitViewViewController];

    return self.rootWindow;
}

- (void)replaceRootWindow:(UIWindow *)newWindow
{
    UIView *toView = newWindow.rootViewController.view;
    toView.frame = self.rootWindow.bounds;
    UIView *snapShotView = [self.rootWindow snapshotViewAfterScreenUpdates:YES];

    [newWindow.rootViewController.view addSubview:snapShotView];
    self.rootWindow = newWindow;

    [UIView animateWithDuration:0.3 animations:^{
        snapShotView.layer.opacity = 0;
        snapShotView.layer.transform = CATransform3DMakeScale(1.5, 1.5, 1.5);
    } completion:^(BOOL finished) {
        [snapShotView removeFromSuperview];
    }];
}

@end
