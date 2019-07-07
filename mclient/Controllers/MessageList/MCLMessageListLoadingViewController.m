//
//  MCLMessageListLoadingViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageListLoadingViewController.h"

#import "MCLDependencyBag.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessageListRequest.h"
#import "MCLMessageListViewController.h"
#import "MCLErrorViewController.h"
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

- (void)stopLoading
{
    [super stopLoading];

    MCLMessageListViewController *messageListVC = ((MCLMessageListViewController *)self.contentViewController);
    [messageListVC.delegate messageListViewController:messageListVC didFinishLoadingThread:messageListVC.thread];
}

- (void)loadThread:(MCLThread *)thread
{
    assert(thread.board != nil);
    assert(thread.boardId != nil);

    MCLMessageListRequest *request = [[MCLMessageListRequest alloc] initWithClient:self.bag.httpClient thread:thread];
    self.requests = @{@(0): request};

    MCLMessageListViewController *messageListVC = ((MCLMessageListViewController *)self.contentViewController);
    [messageListVC setBoard:thread.board];
    [messageListVC setThread:thread];
    [self updateTitle];
    
    [self startLoading];
    [request loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        [self stopLoading];

        if (error || !data) {
            [self showErrorOfType:kMCLErrorTypeGeneral error:error];
            return;
        }

        [messageListVC loadingViewController:self hasRefreshedWithData:data forKey:@(0)];
    }];
}

@end
