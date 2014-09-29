//
//  MCLThread.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLThread.h"

@implementation MCLThread

+ (id)threadWithId:(NSNumber *)inThreadId
         messageId:(NSNumber *)inMessageId
            sticky:(BOOL)inSticky
            closed:(BOOL)inClosed
               mod:(BOOL)inMod
          username:(NSString *)inUsername
           subject:(NSString *)inSubject
              date:(NSDate *)inDate
       answerCount:(NSNumber *)inAnswerCount
        answerDate:(NSDate *)inAnswerDate
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
    thread.answerCount = inAnswerCount;
    thread.answerDate = inAnswerDate;
    
    return thread;
}

@end
