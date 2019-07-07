//
//  MCLRouter.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRouter.h"

#import "MCLDependencyBag.h"
#import "MCLRouterDelegate.h"
#import "MCLFeatures.h"
#import "MCLLoginManager.h"
#import "MCLThemeManager.h"
#import "MCLSplitViewController.h"
#import "MCLLaunchViewController.h"
#import "MCLTerminationViewController.h"
#import "MCLDetailNavigationController.h"


@interface MCLRouter () <UISplitViewControllerDelegate>

@property (weak, nonatomic) UIWindow *rootWindow;
@property (strong, nonatomic) UIWindow *launchWindow;
@property (strong, nonatomic) MCLLaunchViewController *launchViewController;

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

#pragma mark - Private

- (UIWindow *)makeWindowWithViewController:(UIViewController *)rootViewController
{
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.rootViewController = rootViewController;
    window.hidden = NO;

    return window;
}

- (UIWindow *)makeLaunchWindow
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LaunchScreen" bundle:nil];
    UIViewController *storyboardLaunchVC = [storyboard instantiateViewControllerWithIdentifier:@"MCLLaunchViewController"];
    self.launchViewController = [[MCLLaunchViewController alloc] initWithLaunchViewController:storyboardLaunchVC];

    UIWindow *launchWindow = [self makeWindowWithViewController:self.launchViewController];
    launchWindow.windowLevel = UIWindowLevelNormal + 1.0f;

    return launchWindow;
}

- (void)makeTerminationWindowWithWindowHandler:(void (^)(UIWindow *rootWindow))windowHandler
{
    MCLTerminationViewController *terminationVC = [[MCLTerminationViewController alloc] initWithBag:self.bag];
    self.rootWindow = [self makeWindowWithViewController:terminationVC];
    windowHandler(self.rootWindow);
    [self.rootWindow makeKeyAndVisible];
}

- (void)makeRootWindowWithWindowHandler:(void (^)(UIWindow *rootWindow))windowHandler completionHandler:(void (^)(void))completionHandler
{
    assert(self.delegate != nil);

    self.splitViewController = [[MCLSplitViewController alloc] initWithBag:self.bag];

    UIViewController *masterViewController = [self.delegate createMasterViewControllerForRouter:self withCompletionHandler:completionHandler];
    self.masterNavigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];

    UIViewController *detailViewController = [self.delegate createDetailViewControllerForRouter:self];
    self.detailNavigationController = [[MCLDetailNavigationController alloc] initWithBag:self.bag
                                                                      rootViewController:detailViewController];

    NSMutableArray *splitViews = [[NSMutableArray alloc] init];
    [splitViews addObject:self.masterNavigationController];
    [splitViews addObject:self.detailNavigationController];
    self.splitViewController.viewControllers = splitViews;
    self.splitViewController.delegate = self;

    if (!self.splitViewController.isCollapsed) {
        self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    }

    self.rootWindow = [self makeWindowWithViewController:self.splitViewController];
    windowHandler(self.rootWindow);
}

- (void)removeLaunchWindow
{
    self.launchViewController.loadingContainerView.hidden = YES;
    
    UIView *snapShotView = [self.launchWindow snapshotViewAfterScreenUpdates:YES];
    [self.rootWindow.rootViewController.view addSubview:snapShotView];
    [self.rootWindow makeKeyAndVisible];
    self.launchWindow = nil;

    [UIView animateWithDuration:0.3f animations:^{
        snapShotView.layer.opacity = 0.0f;
        snapShotView.layer.transform = CATransform3DMakeScale(1.5f, 1.5f, 1.5f);
    } completion:^(BOOL finished) {
        [snapShotView removeFromSuperview];
    }];
}

#pragma mark - Public Methods

- (void)launchRootWindow:(void (^)(UIWindow *window))windowHandler
{
    if ([self.bag.features isFeatureWithNameEnabled:MCLFeatureTermination]) {
        [self makeTerminationWindowWithWindowHandler:windowHandler];
        return;
    }

    self.launchWindow = [self makeLaunchWindow];
    windowHandler(self.launchWindow);
    [self.launchWindow makeKeyAndVisible];

    [self.bag.loginManager performLoginWithCompletionHandler:^(NSError *error, BOOL success) {
        [self makeRootWindowWithWindowHandler:windowHandler completionHandler:^{
            [self removeLaunchWindow];
        }];
    }];
}

- (BOOL)modalIsPresented
{
    BOOL modalIsPresented = [self.modalNavigationController presentingViewController] != nil;
    BOOL masterIsPresented = [self.masterNavigationController presentingViewController] != nil;

    return modalIsPresented || masterIsPresented;
}

- (void)dismissModalIfPresentedWithCompletionHandler:(void (^)(BOOL dismissed))completionHandler
{
    if ([self modalIsPresented]) {
        [self.modalNavigationController dismissViewControllerAnimated:YES completion:^{
            if (completionHandler) {
                completionHandler(YES);
            }
        }];
        return;
    }

    if (completionHandler) {
        completionHandler(NO);
    }
}

@end
