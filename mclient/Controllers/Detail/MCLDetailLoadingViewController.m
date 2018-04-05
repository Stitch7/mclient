//
//  MCLDetailLoadingViewController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLDetailLoadingViewController.h"

#import "MCLLogin.h"
#import "MCLThreadListTableViewController.h"

@implementation MCLDetailLoadingViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag request:(id<MCLRequest>)request contentViewController:(UIViewController *)contentViewController configure:(void (^)(NSArray*))configure;
{
    self = [super initWithBag:bag request:request contentViewController:contentViewController configure:configure];
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
                                             selector:@selector(favoritesChanged:)
                                                 name:MCLFavoritedChangedNotification
                                               object:nil];
}

- (void)loginStateDidChanged:(NSNotification *)notification
{
    [self refresh];
}

- (void)favoritesChanged:(NSNotification *)notification
{
    [self refresh];
}

@end
