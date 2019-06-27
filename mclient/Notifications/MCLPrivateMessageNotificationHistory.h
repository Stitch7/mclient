//
//  MCLPrivateMessageNotificationHistory.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLPrivateMessage;

@interface MCLPrivateMessageNotificationHistory : NSObject

- (void)addPrivateMessage:(MCLPrivateMessage *)privateMessage;
- (void)removePrivateMessage:(MCLPrivateMessage *)privateMessage;
- (void)removeMessageId:(NSNumber *)messageId;
- (BOOL)privateMessageWasAlreadyPresented:(MCLPrivateMessage *)privateMessage;
- (void)persist;

@end


