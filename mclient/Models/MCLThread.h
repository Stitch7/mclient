//
//  MCLThread.h
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCLThread : NSObject

@property (strong) NSNumber *threadId;
@property (strong) NSNumber *messageId;
@property (nonatomic, assign, getter=isRead) BOOL read;
@property (nonatomic, assign, getter=isTemporaryRead) BOOL tempRead;
@property (nonatomic, assign, getter=isSticky) BOOL sticky;
@property (nonatomic, assign, getter=isClosed) BOOL closed;
@property (nonatomic, assign, getter=isMod) BOOL mod;
@property (strong) NSString *username;
@property (strong) NSString *subject;
@property (strong) NSDate *date;
@property (strong) NSNumber *messagesCount;
@property (strong) NSNumber *messagesRead;
@property (strong) NSNumber *lastMessageId;
@property (nonatomic, assign, getter=lastMessageIsRead) BOOL lastMessageRead;
@property (strong) NSDate *lastMessageDate;

+ (MCLThread *)threadWithId:(NSNumber *)inThreadId
                  messageId:(NSNumber *)inMessageId
                       read:(BOOL)inRead
                     sticky:(BOOL)inSticky
                     closed:(BOOL)inClosed
                        mod:(BOOL)inMod
                   username:(NSString *)inUsername
                    subject:(NSString *)inSubject
                       date:(NSDate *)inDate
               messagesCount:(NSNumber *)inMessagesCount
               messagesRead:(NSNumber *)inMessagesRead
              lastMessageId:(NSNumber *)inLastMessageId
            lastMessageRead:(BOOL)inLastMessageRead
            lastMessageDate:(NSDate *)inLastMessageDate;

@end
