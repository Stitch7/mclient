//
//  MCLReadList.h
//  mclient
//
//  Created by Christopher Reitz on 31.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MCLThread;

@interface MCLReadList : NSObject

- (void)addMessageId:(NSNumber *)messageId fromThread:(MCLThread *)thread;
- (void)addMessages:(NSArray *)messages fromThread:(MCLThread *)thread;
- (BOOL)messageIdIsRead:(NSNumber *)messageId fromThread:(MCLThread *)thread;
- (NSArray *)messagesFromThread:(MCLThread *)thread;
- (NSNumber *)readMessagesCountFromThread:(MCLThread *)threadId;

@end
