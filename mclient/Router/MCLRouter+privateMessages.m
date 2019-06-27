//
//  MCLRouter+privateMessages.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRouter+privateMessages.h"

#import "MCLSplitViewController.h"
#import "MCLPrivateMessagesManager.h"
#import "MCLPrivateMessagesViewController.h"
#import "MCLUserSearchViewController.h"


@implementation MCLRouter (privateMessages)

- (MCLPrivateMessagesViewController *)pushToPrivateMessages
{
    MCLPrivateMessagesViewController *privateMessagesVC = [[MCLPrivateMessagesViewController alloc] initWithBag:self.bag];
    [self.masterNavigationController pushViewController:privateMessagesVC animated:YES];

    return privateMessagesVC;
}

- (void)pushToPrivateMessagesConversation:(MCLPrivateMessageConversation *)conversation
{
    BasicChatViewController *chatVC = [[BasicChatViewController alloc] init];
    chatVC.bag = self.bag;
    chatVC.conversation = conversation;

    if (self.splitViewController.isCollapsed) {
        [self.masterNavigationController pushViewController:chatVC animated:YES];
    } else {
        if ([self.detailNavigationController.viewControllers.lastObject isKindOfClass:[ChatViewController class]]) {
            NSMutableArray *vcs = [NSMutableArray arrayWithArray:self.detailNavigationController.viewControllers];
            [vcs removeLastObject];
            [vcs addObject:chatVC];
            [self.detailNavigationController setViewControllers:vcs];
        } else {
            [self.detailNavigationController pushViewController:chatVC animated:YES];
        }
    }
}

- (MCLUserSearchViewController *)pushToUserSearch
{
    MCLUserSearchViewController *userSearchVC = [[MCLUserSearchViewController alloc] initWithBag:self.bag];
    [self.masterNavigationController pushViewController:userSearchVC animated:YES];

    return userSearchVC;
}

@end
