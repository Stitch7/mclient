//
//  MCLRouter+mainNavigation.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRouter+mainNavigation.h"

#import "MCLDependencyBag.h"
#import "MCLSettings.h"
#import "MCLLogin.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLUser.h"
#import "MCLSplitViewController.h"
#import "MCLDetailViewController.h"
#import "MCLModalNavigationController.h"
#import "MCLSettingsViewController.h"
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
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
    MCLSettingsViewController *settingsVC = [storyboard instantiateViewControllerWithIdentifier:@"MCLSettingsViewController"];
    settingsVC.bag = self.bag; // TODO: - do proper DI

    MCLModalNavigationController *navigationVC = [[MCLModalNavigationController alloc] initWithRootViewController:settingsVC];
    [self.masterNavigationController presentViewController:navigationVC animated:YES completion:nil];

    return settingsVC;
}

- (MCLProfileTableViewController *)modalToProfileFromUser:(MCLUser *)user
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
    MCLProfileTableViewController *profileVC = [storyboard instantiateViewControllerWithIdentifier:@"MCLProfileTableViewController"];
    profileVC.bag = self.bag;
    profileVC.user = user;

    MCLProfileRequest *profileRequest = [[MCLProfileRequest alloc] initWithClient:self.bag.httpClient user:user];
    MCLLoadingViewController *loadingVC = [[MCLLoadingViewController alloc] initWithBag:self.bag
                                                                                request:profileRequest
                                                                  contentViewController:profileVC];

    loadingVC.modalPresentationStyle = UIModalPresentationFormSheet;
    MCLModalNavigationController *navigationVC = [[MCLModalNavigationController alloc] initWithRootViewController:loadingVC];
    [self.masterNavigationController presentViewController:navigationVC animated:YES completion:nil];

    return profileVC;
}

- (MCLResponsesTableViewController *)pushToResponses
{
    MCLMessageResponsesRequest *responsesRequest = [[MCLMessageResponsesRequest alloc] initWithBag:self.bag];
    MCLResponsesTableViewController *responsesVC = [[MCLResponsesTableViewController alloc] initWithBag:self.bag];

    MCLLoadingViewController *loadingVC = [[MCLLoadingViewController alloc] initWithBag:self.bag
                                                                                request:responsesRequest
                                                                  contentViewController:responsesVC];

    if (self.splitViewViewController.collapsed) {
        [self.masterNavigationController pushViewController:loadingVC animated:YES];
    } else {
        [self.detailNavigationController pushViewController:loadingVC animated:YES];
    }

    return responsesVC;
}

- (MCLThreadListTableViewController *)pushToThreadListFromBoard:(MCLBoard *)board
{
    MCLThreadListTableViewController *threadListVC = [[MCLThreadListTableViewController alloc] initWithBag:self.bag];
    threadListVC.board = board;

    MCLThreadListRequest *threadListRequest = [[MCLThreadListRequest alloc] initWithClient:self.bag.httpClient
                                                                                     board:board
                                                                                     login:self.bag.login];
    MCLLoadingViewController *loadingVC = [[MCLLoadingViewController alloc] initWithBag:self.bag
                                                                                request:threadListRequest
                                                                  contentViewController:threadListVC];
    loadingVC.title = board.name;
    [self.masterNavigationController pushViewController:loadingVC animated:YES];

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
    self.detailViewController = [[MCLMessageListLoadingViewController alloc] initWithBag:self.bag
                                                                                 request:messageListRequest
                                                                   contentViewController:messageListVC];
    self.detailViewController.navigationItem.titleView = [messageListVC titleLabel];

    if (self.splitViewViewController.collapsed) {
        [masterNavigationController pushViewController:self.detailViewController animated:YES];
    } else if (!forceDetailPush && [self currentDetailVcIsMessageList]) {
        UIViewController *currentDetailVC = [[self.detailNavigationController viewControllers] lastObject];
        MCLMessageListLoadingViewController *loadingVC = (MCLMessageListLoadingViewController *)currentDetailVC;
        [loadingVC loadThread:thread];
    } else {
        [self.detailNavigationController pushViewController:self.detailViewController animated:YES];
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

    return [self pushToThread:message.thread
              forceDetailPush:NO
 onMasterNavigationController:masterNavigationController
              jumpToMessageId:message.messageId];
}

@end
