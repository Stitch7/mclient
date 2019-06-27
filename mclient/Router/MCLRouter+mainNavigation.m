//
//  MCLRouter+mainNavigation.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRouter+mainNavigation.h"

#import "MCLDependencyBag.h"
#import "MCLFeatures.h"
#import "MCLSettings.h"
#import "MCLLoginManager.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLUser.h"
#import "MCLSplitViewController.h"
#import "MCLDetailViewController.h"
#import "MCLModalNavigationController.h"
#import "MCLSettingsViewController.h"
#import "MCLTabbedSettingsModallNavigationControllerViewController.h"
#import "MCLSearchTableViewController.h"
#import "MCLResponsesTableViewController.h"
#import "MCLThreadListTableViewController.h"
#import "MCLLoadingViewController.h"
#import "MCLMessageListLoadingViewController.h"
#import "MCLMessageListViewController.h"
#import "MCLMessageListFrameStyleViewController.h"
#import "MCLMessageListWidmannStyleViewController.h"
#import "MCLProfileTableViewController.h"
#import "MCLThreadListRequest.h"
#import "MCLMessageListRequest.h"
#import "MCLMessageResponsesRequest.h"
#import "MCLProfileRequest.h"


@implementation MCLRouter (mainNavigation)

- (MCLSettingsViewController *)modalToSettings
{
    if ([self.bag.features isFeatureWithNameEnabled:MCLFeatureTabbedSettings]) {
        UIStoryboard *tabbedStoryboard = [UIStoryboard storyboardWithName:@"TabbedSettings" bundle:nil];
        UITabBarController *tabbedSettingsVC = [tabbedStoryboard instantiateViewControllerWithIdentifier:@"MCLSettingsTabBarController"];
        tabbedSettingsVC.modalPresentationStyle = UIModalPresentationFormSheet;

        self.modalNavigationController = [[MCLTabbedSettingsModallNavigationControllerViewController alloc] initWithRootViewController:tabbedSettingsVC];
        [self.masterNavigationController presentViewController:self.modalNavigationController animated:YES completion:nil];

        return [[MCLSettingsViewController alloc] init]; // To avoid warning, change return type when feature flag get's removed
    }

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
    MCLSettingsViewController *settingsVC = [storyboard instantiateViewControllerWithIdentifier:@"MCLSettingsViewController"];
    settingsVC.bag = self.bag;

    self.modalNavigationController = [[MCLModalNavigationController alloc] initWithRootViewController:settingsVC];
    [self.masterNavigationController presentViewController:self.modalNavigationController animated:YES completion:nil];

    return settingsVC;
}

- (MCLProfileTableViewController *)modalToProfileFromUser:(MCLUser *)user
{
    MCLProfileTableViewController *profileVC = [[MCLProfileTableViewController alloc] init];
    profileVC.bag = self.bag;
    profileVC.user = user;
    profileVC.showPrivateMessagesButton = [self.bag.features isFeatureWithNameEnabled:MCLFeaturePrivateMessages];

    MCLProfileRequest *profileRequest = [[MCLProfileRequest alloc] initWithClient:self.bag.httpClient user:user];
    MCLLoadingViewController *loadingVC = [[MCLLoadingViewController alloc] initWithBag:self.bag
                                                                                request:profileRequest
                                                                  contentViewController:profileVC];

    loadingVC.modalPresentationStyle = UIModalPresentationFormSheet;
    self.modalNavigationController = [[MCLModalNavigationController alloc] initWithRootViewController:loadingVC];
    [self.masterNavigationController presentViewController:self.modalNavigationController animated:YES completion:nil];

    return profileVC;
}

- (MCLSearchTableViewController *)pushToSearchWithBoards:(NSArray<MCLBoard *>*)boards
{
    MCLSearchTableViewController *searchTableVC = [[MCLSearchTableViewController alloc] initWithBag:self.bag boards:boards];

    [self.masterNavigationController pushViewController:searchTableVC animated:YES];

    return searchTableVC;
}

- (MCLResponsesTableViewController *)pushToResponses
{
    MCLMessageResponsesRequest *responsesRequest = [[MCLMessageResponsesRequest alloc] initWithBag:self.bag];
    MCLResponsesTableViewController *responsesVC = [[MCLResponsesTableViewController alloc] initWithBag:self.bag];

    MCLLoadingViewController *loadingVC = [[MCLLoadingViewController alloc] initWithBag:self.bag
                                                                                request:responsesRequest
                                                                  contentViewController:responsesVC];
    [self.masterNavigationController pushViewController:loadingVC animated:YES];

    return responsesVC;
}

- (MCLThreadListTableViewController *)pushToThreadListFromBoard:(MCLBoard *)board
{
    MCLThreadListTableViewController *threadListVC = [[MCLThreadListTableViewController alloc] initWithBag:self.bag];
    threadListVC.board = board;

    MCLThreadListRequest *threadListRequest = [[MCLThreadListRequest alloc] initWithClient:self.bag.httpClient
                                                                                     board:board
                                                                                     loginManager:self.bag.loginManager];
    MCLLoadingViewController *loadingVC = [[MCLLoadingViewController alloc] initWithBag:self.bag
                                                                                request:threadListRequest
                                                                  contentViewController:threadListVC];
    loadingVC.title = board.name;

    BOOL replace = NO;
    MCLLoadingViewController *currentVC = (MCLLoadingViewController *)[[self.masterNavigationController viewControllers] lastObject];
    if (currentVC && [currentVC respondsToSelector:NSSelectorFromString(@"contentViewController")] &&
        [currentVC.contentViewController isKindOfClass:[MCLThreadListTableViewController class]])
    {
        replace = YES;
    }

    if (replace) {
        NSMutableArray *newViewControllers = [[self.masterNavigationController viewControllers] mutableCopy];
        [newViewControllers removeLastObject];
        [newViewControllers addObject:loadingVC];
        [self.masterNavigationController setViewControllers:newViewControllers];
    } else {
        [self.masterNavigationController pushViewController:loadingVC animated:YES];
    }

    return threadListVC;
}

- (MCLMessageListViewController *)pushToThread:(MCLThread *)thread
{
    return [self pushToThread:thread forceDetailPush:NO];
}

- (MCLMessageListViewController *)pushToThread:(MCLThread *)thread onMasterNavigationController:(UINavigationController *)masterNavigationController
{
    return [self pushToThread:thread forceDetailPush:NO onMasterNavigationController:masterNavigationController];
}

- (MCLMessageListViewController *)pushToThread:(MCLThread *)thread forceDetailPush:(BOOL)forceDetailPush
{
    return [self pushToThread:thread forceDetailPush:forceDetailPush onMasterNavigationController:self.masterNavigationController];
}

- (MCLMessageListViewController *)pushToThread:(MCLThread *)thread forceDetailPush:(BOOL)forceDetailPush onMasterNavigationController:(UINavigationController *)masterNavigationController
{
    return [self pushToThread:thread forceDetailPush:forceDetailPush onMasterNavigationController:masterNavigationController jumpToMessageId:nil];
}

- (MCLMessageListViewController *)pushToThread:(MCLThread *)thread forceDetailPush:(BOOL)forceDetailPush onMasterNavigationController:(UINavigationController *)masterNavigationController jumpToMessageId:(NSNumber *)messageId
{
    assert(thread.board != nil);
    assert(thread.board.boardId != nil);

    if (!forceDetailPush && [self currentDetailVcIsMessageList]) {
        UIViewController *currentDetailVC = [[self.detailNavigationController viewControllers] lastObject];
        MCLMessageListLoadingViewController *loadingVC = (MCLMessageListLoadingViewController *)currentDetailVC;
        [loadingVC loadThread:thread];
        return [loadingVC.childViewControllers firstObject];
    }

    MCLMessageListViewController *messageListVC;
    switch ([self.bag.settings integerForSetting:MCLSettingThreadView]) {
        case kMCLSettingsThreadViewWidmann:
        default:
            messageListVC = [[MCLMessageListWidmannStyleViewController alloc] initWithBag:self.bag];
            break;
        case kMCLSettingsThreadViewFrame:
            messageListVC = [[MCLMessageListFrameStyleViewController alloc] initWithBag:self.bag];
            break;
    }
    messageListVC.board = thread.board;
    messageListVC.thread = thread;
    if (messageId) {
        messageListVC.jumpToMessageId = messageId;
    }

    MCLMessageListRequest *messageListRequest = [[MCLMessageListRequest alloc] initWithClient:self.bag.httpClient
                                                                                       thread:thread];
    MCLMessageListLoadingViewController *messageListLoadingVC = [[MCLMessageListLoadingViewController alloc] initWithBag:self.bag
                                                                                                                 request:messageListRequest
                                                                                                   contentViewController:messageListVC];
    if (self.splitViewController.isCollapsed) {
        [masterNavigationController pushViewController:messageListLoadingVC animated:YES];
    } else {
        messageListLoadingVC.navigationItem.titleView = [messageListVC titleLabel];
        [self.detailNavigationController pushViewController:messageListLoadingVC animated:YES];
    }

    return messageListVC;
}

- (BOOL)currentDetailVcIsMessageList
{
    UIViewController *currentDetailVC = [[self.detailNavigationController viewControllers] lastObject];
    return [currentDetailVC isKindOfClass:[MCLMessageListLoadingViewController class]];
}

- (MCLMessageListViewController *)pushToMessage:(MCLMessage *)message
{
    assert(message.thread != nil);
    assert(message.thread.board != nil);

    return [self pushToThread:message.thread forceDetailPush:YES onMasterNavigationController:self.masterNavigationController jumpToMessageId:message.messageId];
}

- (MCLMessageListViewController *)pushToMessage:(MCLMessage *)message onMasterNavigationController:(UINavigationController *)masterNavigationController
{
    assert(message.thread != nil);
    assert(message.thread.board != nil);

    return [self pushToThread:message.thread forceDetailPush:NO onMasterNavigationController:masterNavigationController jumpToMessageId:message.messageId];
}

@end
