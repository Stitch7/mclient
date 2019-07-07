//
//  MCLPrivateMessagesManager.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLPrivateMessagesManager.h"

#import "MCLDependencyBag.h"
#import "MCLFeatures.h"
#import "MCLUser.h"
#import "MCLPrivateMessagesListRequest.h"
#import "MCLPrivateMessage.h"
#import "MCLPrivateMessageConversation.h"

#import "mclient-Swift.h"

NSString * const MCLPrivateMessagesChangedNotification = @"MCLPrivateMessagesChangedNotification";

@interface MCLPrivateMessagesManager ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;

@end


@implementation MCLPrivateMessagesManager

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;
    self.privateMessagesCache = [[PrivateMessagesCacheUserDefaults alloc] init];

    return self;
}

#pragma mark - Public

- (MCLPrivateMessageConversation *)conversationForUser:(MCLUser *)user
{
    MCLPrivateMessageConversation *conversation;
    for (MCLPrivateMessageConversation *existingConversation in self.bag.privateMessagesManager.conversations) {
        if ([existingConversation.username isEqualToString:user.username]) {
            conversation = existingConversation;
            break;
        }
    }

    if (!conversation) {
        conversation = [[MCLPrivateMessageConversation alloc] init];
        conversation.username = user.username;
        conversation.messages = [[NSMutableArray alloc] init];
    }

    return conversation;
}

- (void)removePrivateMessageAtRow:(NSInteger)row fromUser:(MCLUser *)user
{
    for (MCLPrivateMessageConversation *conversation in self.conversations) {
        if ([conversation.username isEqualToString:user.username]) {
            [conversation.messages removeObjectAtIndex:row];
            [self sendChangedNotification];
            break;
        }
    }
}

- (NSNumber *)numberOfUnreadMessages
{
    if (!self.conversations) {
        return @0;
    }
    int num = 0;
    for (MCLPrivateMessageConversation *conversation in self.conversations) {
        for (MCLPrivateMessage *pm in conversation.messages) {
            if (!pm.isRead) {
                num++;
            }
        }
    }

    return [NSNumber numberWithInteger:num];
}

- (void)loadConversations
{
    [self loadConversationsWithCompletionHandler:nil];
}

- (void)loadConversationsWithCompletionHandler:(void (^)(NSArray*))completionHandler
{
    if (![self.bag.features isFeatureWithNameEnabled:MCLFeaturePrivateMessages]) {
        return;
    }

    MCLPrivateMessagesListRequest *privateMessagesRequest = [[MCLPrivateMessagesListRequest alloc] initWithClient:self.bag.httpClient];
    [privateMessagesRequest loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        if (error) {
            return; // TODO
        }
        self.conversations = [data copy];
        if (completionHandler) {
            completionHandler(self.conversations);
        }
        [self sendChangedNotification];
    }];
}

- (void)sendChangedNotification
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              [self numberOfUnreadMessages], @"numberOfUnreadMessages", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:MCLPrivateMessagesChangedNotification
                                                        object:self
                                                      userInfo:userInfo];
}

@end
