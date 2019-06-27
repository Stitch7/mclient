//
//  MCLPrivateMessageConversation.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLPrivateMessage;

@interface MCLPrivateMessageConversation : NSObject

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSMutableArray *messages;

@property (strong, nonatomic, readonly) MCLPrivateMessage *lastMessage;

+ (MCLPrivateMessageConversation *)conversationFromJSON:(NSDictionary *)json;

- (BOOL)hasUnreadMessages;

@end
