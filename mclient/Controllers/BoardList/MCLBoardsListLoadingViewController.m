//
//  MCLBoardsListLoadingViewController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLBoardsListLoadingViewController.h"

#import "MCLLogin.h"
#import "MCLBoardListTableViewController.h"
#import "MCLThreadListTableViewController.h"


@implementation MCLBoardsListLoadingViewController

#pragma mark - UIViewController life cycle

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateTitle];
        [[self.delegate tableView] reloadData];
    }];
}

#pragma mark - Notifications

- (void)configureNotifications
{
    [super configureNotifications];

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
