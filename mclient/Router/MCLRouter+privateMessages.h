//
//  MCLRouter+privateMessages.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRouter.h"


@class MCLPrivateMessageConversation;
@class MCLPrivateMessagesViewController;
@class MCLUserSearchViewController;

@interface MCLRouter (privateMessages)

- (MCLPrivateMessagesViewController *)pushToPrivateMessages;
- (void)pushToPrivateMessagesConversation:(MCLPrivateMessageConversation *)conversation;
- (MCLUserSearchViewController *)pushToUserSearch;

@end
