//
//  MCLNotificationHistory.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLResponse;

@interface MCLNotificationHistory : NSObject

- (void)addResponse:(MCLResponse *)response;
- (void)removeResponse:(MCLResponse *)response;
- (void)removeMessageId:(NSNumber *)messageId;
- (BOOL)responseWasAlreadyPresented:(MCLResponse *)response;
- (void)persist;

@end
