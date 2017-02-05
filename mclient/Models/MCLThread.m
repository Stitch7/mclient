//
//  MCLThread.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLThread.h"

@implementation MCLThread

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
            lastMessageDate:(NSDate *)inLastMessageDate
{
    MCLThread *thread = [[MCLThread alloc] init];
    
    thread.threadId = inThreadId;
    thread.messageId = inMessageId;
    thread.read = inRead;
    thread.tempRead = inRead;
    thread.sticky = inSticky;
    thread.closed = inClosed;
    thread.mod = inMod;
    thread.username = inUsername;
    thread.subject = inSubject;
    thread.date = inDate;
    thread.messagesCount = inMessagesCount;
    thread.messagesRead = inMessagesRead;
    thread.lastMessageId = inLastMessageId;
    thread.lastMessageRead = inLastMessageRead;
    thread.lastMessageDate = inLastMessageDate;
    
    return thread;
}

@end
