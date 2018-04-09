//
//  MCLMessageListLoadingViewController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageListLoadingViewController.h"

#import "MCLDependencyBag.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessageListRequest.h"
#import "MCLMessageListViewController.h"
#import "MCLLoadingViewControllerDelegate.h"
#import "MCLSettingsViewController.h"

@implementation MCLMessageListLoadingViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag request:(id<MCLRequest>)request contentViewController:(UIViewController *)contentViewController
{
    self = [super initWithBag:bag request:request contentViewController:contentViewController];
    if (!self) return nil;

    [self configureNotifications];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications

- (void)configureNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(threadViewStyleChanged:)
                                                 name:MCLThreadViewStyleChangedNotification
                                               object:nil];
}

- (void)threadViewStyleChanged:(NSNotification *)notification
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Public

- (void)loadThread:(MCLThread *)thread
{
    assert(thread.board != nil);
    assert(thread.boardId != nil);

    self.request = [[MCLMessageListRequest alloc] initWithClient:self.bag.httpClient thread:thread];

    MCLMessageListViewController *messageListVC = ((MCLMessageListViewController *)self.contentViewController);
    [messageListVC setBoard:thread.board];
    [messageListVC setThread:thread];
    [self updateTitle];
    
    [self startLoading];
    [self.request loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        [self stopLoading];

        if (error || !data) {
            [self showErrorView:error];
            return;
        }

        [messageListVC loadingViewController:self hasRefreshedWithData:data];
    }];
}

@end
