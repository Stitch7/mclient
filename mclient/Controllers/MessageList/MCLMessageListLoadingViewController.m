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

@implementation MCLMessageListLoadingViewController

#pragma mark - Public

- (void)loadThread:(MCLThread *)thread
{
    assert(thread.board != nil);
    assert(thread.boardId != nil);

    self.request = [[MCLMessageListRequest alloc] initWithClient:self.bag.httpClient thread:thread];

    MCLMessageListViewController *contentViewController = ((MCLMessageListViewController *)self.contentViewController);
    [contentViewController setBoard:thread.board];
    [contentViewController setThread:thread];
    [self updateTitle];
    
    [self startLoading];
    [self.request loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        [self stopLoading];

        if (error || !data) {
            [self showErrorView:error];
            return;
        }

        if ([self.delegate respondsToSelector:@selector(loadingViewController:hasRefreshedWithData:)]) {
            [self.delegate loadingViewController:self hasRefreshedWithData:data];
        }
    }];
}

@end
