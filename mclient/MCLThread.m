//
//  MCLThread.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLThread.h"

@implementation MCLThread

+ (id) threadWithId:(int)inId sticky:(BOOL)inSticky closed:(BOOL)inClosed mod:(BOOL)inMod author:(NSString*)inAuthor subject:(NSString*)inSubject date:(NSString*)inDate answerCount:(int)inAnswerCount answerDate:(NSString*)inAnswerDate
{
    MCLThread *thread = [[MCLThread alloc] init];
    
    thread.threadId = inId;
    thread.sticky = inSticky;
    thread.closed = inClosed;
    thread.mod = inMod;
    thread.author = inAuthor;
    thread.subject = inSubject;
    thread.date = inDate;
    thread.answerCount = inAnswerCount;
    thread.answerDate = inAnswerDate;
    
    return thread;
}

@end
