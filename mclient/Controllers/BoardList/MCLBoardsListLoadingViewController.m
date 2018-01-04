//
//  MCLBoardsListLoadingViewController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLBoardsListLoadingViewController.h"

#import "MCLLogin.h"
#import "MCLThreadListTableViewController.h"

@interface MCLBoardsListLoadingViewController ()

@end

@implementation MCLBoardsListLoadingViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id<MCLDependencyBag>)bag requests:(NSArray<__kindof id<MCLRequest>> *)requests forViewController:(UIViewController *)viewController
{
    self = [super initWithBag:bag requests:requests forViewController:viewController];
    if (!self) return nil;

    [self configureNotifications];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController life cycle

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateTitle];
        [[self.delegate tableView] reloadData];
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
                                             selector:@selector(favoritesChanged)
                                                 name:MCLFavoritedChangedNotification
                                               object:nil];
}

- (void)loginStateDidChanged:(NSNotification *)notification
{
    // crashes... :-|
//    [self load];
}

- (void)favoritesChanged
{
    [self load];
}

@end
