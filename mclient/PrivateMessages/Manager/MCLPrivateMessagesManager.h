//
//  MCLPrivateMessagesManager.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;
@protocol PrivateMessagesCache;
@class MCLPrivateMessageConversation;
@class MCLUser;

extern NSString * const MCLPrivateMessagesChangedNotification;

@interface MCLPrivateMessagesManager : NSObject

@property (strong, nonatomic) id <PrivateMessagesCache> privateMessagesCache;
@property (strong, nonatomic) NSArray *conversations;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;

- (NSNumber *)numberOfUnreadMessages;
- (void)loadConversations;
- (void)loadConversationsWithCompletionHandler:(void (^)(NSArray*))completionHandler;
- (MCLPrivateMessageConversation *)conversationForUser:(MCLUser *)user;
- (void)removePrivateMessageAtRow:(NSInteger)row fromUser:(MCLUser *)user;

@end
