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
                     sticky:(BOOL)inSticky
                     closed:(BOOL)inClosed
                        mod:(BOOL)inMod
                   username:(NSString *)inUsername
                    subject:(NSString *)inSubject
                       date:(NSDate *)inDate
                messageCount:(NSNumber *)inMessageCount
                lastMessageId:(NSNumber *)inLastMessageId
                 lastMessageDate:(NSDate *)inLastMessageDate
{
    MCLThread *thread = [[MCLThread alloc] init];
    
    thread.threadId = inThreadId;
    thread.messageId = inMessageId;
    thread.sticky = inSticky;
    thread.closed = inClosed;
    thread.mod = inMod;
    thread.username = inUsername;
    thread.subject = inSubject;
    thread.date = inDate;
    thread.messageCount = inMessageCount;
    thread.lastMessageId = inLastMessageId;
    thread.lastMessageDate = inLastMessageDate;
    
    return thread;
}

@end
