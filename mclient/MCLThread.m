//
//  MCLThread.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLThread.h"

@implementation MCLThread

+ (id) threadWithId:(int)inId firstMessageId:(int)inFirstMessageId author:(NSString *)inAuthor subject:(NSString *)inSubject date:(NSString *)inDate answerCount:(NSString *)inAnswerCount answerDate:(NSString *)inAnswerDate
{
    MCLThread *thread = [[MCLThread alloc] init];
    
    thread.id = inId;
    thread.firstMessageId = inFirstMessageId;
    thread.author = inAuthor;
    thread.subject = inSubject;
    thread.date = inDate;
    thread.answerCount = inAnswerCount;
    thread.answerDate = inAnswerDate;
    
    return thread;
}

@end
