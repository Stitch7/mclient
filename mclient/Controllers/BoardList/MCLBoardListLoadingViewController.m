//
//  MCLBoardListLoadingViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLBoardListLoadingViewController.h"

#import "MCLDependencyBag.h"
#import "MCLLoginManager.h"
#import "MCLBoardListTableViewController.h"
#import "MCLThreadListTableViewController.h"


@implementation MCLBoardListLoadingViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag requests:(NSDictionary *)requests contentViewController:(UIViewController *)contentViewController withCompletionHandler:(void (^)(void))completionHandler
{
    self = [super initWithBag:bag requests:requests contentViewController:contentViewController withCompletionHandler:completionHandler];
    if (!self) return nil;

    [self configureNotifications];

    return self;
}

#pragma mark - UIViewController life cycle

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateTitle];
        [[self.delegate tableView] reloadData];
    }];
}

#pragma mark - MCLLoadingViewController overrides

- (void)errorViewButtonPressed:(UIButton *)sender
{
    [self removeErrorViewController];
    [self startLoading];

    // We need to relogin in case when network connection on startup failed
    [self.bag.loginManager performLoginWithCompletionHandler:^(NSError* error, BOOL success) {
        MCLBoardListTableViewController *boardsListVC = (MCLBoardListTableViewController *)self.contentViewController;
        [boardsListVC updateVerifyLoginViewWithSuccess:success];

        [self load];
    }];
}

#pragma mark - Notifications

- (void)configureNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loginStateDidChanged:)
                                                 name:MCLLoginStateDidChangeNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(favoritesChanged:)
                                                 name:MCLFavoritedChangedNotification
                                               object:nil];
}

- (void)loginStateDidChanged:(NSNotification *)notification
{
    BOOL initialAttempt = [[notification.userInfo objectForKey:MCLLoginInitialAttemptKey] boolValue];
    if (!initialAttempt) {
        [self load];
    }
}

- (void)favoritesChanged:(NSNotification *)notification
{
    if ([notification.object isKindOfClass:[MCLBoardListTableViewController class]]) {
        return;
    }

    [self load];
}

@end
