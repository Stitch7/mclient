//
//  MCLAppRouterDelegate.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLAppRouterDelegate.h"

#import "MCLDependencyBag.h"
#import "MCLRouter.h"
#import "MCLBoardListLoadingViewController.h"
#import "MCLBoardListTableViewController.h"
#import "MCLDetailLoadingViewController.h"
#import "MCLDetailViewController.h"
#import "MCLMessageListLoadingViewController.h"
#import "MCLBoardListRequest.h"
#import "MCLFavoritesRequest.h"

@interface MCLAppRouterDelegate ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) UIBarButtonItem *displayModeButton;

@end

@implementation MCLAppRouterDelegate

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;

    return self;
}

#pragma mark - MCLRouterDelegate

- (UIViewController *)createMasterViewControllerForRouter:(MCLRouter *)router withCompletionHandler:(void (^)(void))completionHandler
{
    MCLBoardListTableViewController *boardsListVC = [[MCLBoardListTableViewController alloc] initWithBag:self.bag];
    MCLBoardListRequest *boardListRequest = [[MCLBoardListRequest alloc] initWithClient:self.bag.httpClient];
    MCLFavoritesRequest *favoritesRequest = [[MCLFavoritesRequest alloc] initWithClient:self.bag.httpClient];
    NSDictionary *requests = @{@(MCLBoardListSectionBoards): boardListRequest,
                               @(MCLBoardListSectionFavorites): favoritesRequest};
    MCLBoardListLoadingViewController *loadingVC = [[MCLBoardListLoadingViewController alloc] initWithBag:self.bag
                                                                                                 requests:requests
                                                                                    contentViewController:boardsListVC
                                                                                    withCompletionHandler:completionHandler];
    return loadingVC;
}

- (UIViewController *)createDetailViewControllerForRouter:(MCLRouter *)router
{
    MCLDetailViewController *detailVC = [[MCLDetailViewController alloc] initWithBag:self.bag];
    MCLFavoritesRequest *favoritesRequest = [[MCLFavoritesRequest alloc] initWithClient:self.bag.httpClient];
    MCLDetailLoadingViewController *loadingVC = [[MCLDetailLoadingViewController alloc] initWithBag:self.bag
                                                                                            request:favoritesRequest
                                                                              contentViewController:detailVC];
    return loadingVC;
}

- (UIViewController *)handleSplitViewCollapsingForRouter:(MCLRouter *)router
{
    if ([router.detailNavigationController.viewControllers count] > 1) {
        UIViewController *detailVC = [router.detailNavigationController popViewControllerAnimated:NO];
        self.displayModeButton = detailVC.navigationItem.leftBarButtonItem;
        detailVC.navigationItem.leftBarButtonItem = nil;
        [router.masterNavigationController pushViewController:detailVC animated:NO];
    }

    return router.masterNavigationController;
}


- (UIViewController *)handleSplitViewSeparatingForRouter:(MCLRouter *)router
{
    if ([router.masterNavigationController.topViewController isKindOfClass:[MCLMessageListLoadingViewController class]]) {
        UIViewController *detailVC = [router.masterNavigationController popViewControllerAnimated:NO];
        if (self.displayModeButton) {
            detailVC.navigationItem.leftBarButtonItem = self.displayModeButton;
        }
        [router.detailNavigationController pushViewController:detailVC animated:NO];
    }

    return router.detailNavigationController;
}

@end
