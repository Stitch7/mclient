//
//  MCLPrivateMessageConversation.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLPrivateMessageConversation.h"

#import "MCLPrivateMessage.h"

@implementation MCLPrivateMessageConversation

+ (MCLPrivateMessageConversation *)conversationFromJSON:(NSDictionary *)json
{
    MCLPrivateMessageConversation *conversation = [[MCLPrivateMessageConversation alloc] init];
    conversation.username = [json objectForKey:@"username"];
    conversation.messages = [[NSMutableArray alloc] init];
    for (NSDictionary *messageJson in [json objectForKey:@"messages"]) {
        MCLPrivateMessage *pm = [MCLPrivateMessage privateMessageFromJSON:messageJson];
        if (pm) {
            [conversation.messages addObject:pm];
        }
    }

    return conversation;
}

- (NSDate *)lastMessageDate
{
    MCLPrivateMessage *last = (MCLPrivateMessage *)self.messages.firstObject;
    return last.date;
}

- (MCLPrivateMessage *)lastMessage
{
    return (MCLPrivateMessage *)self.messages.firstObject;
}

- (BOOL)hasUnreadMessages
{
    for (MCLPrivateMessage *message in self.messages) {
        if (!message.isRead) {
            return YES;
        }
    }

    return NO;
}

@end
