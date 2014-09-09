//
//  MCLMessage.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLMessage.h"

@implementation MCLMessage

+ (id)messageWithId:(NSNumber *)inMessageId level:(NSUInteger)inLevel userId:(NSNumber *)inUserId username:(NSString *)inUsername subject:(NSString *)inSubject date:(NSDate *)inDate text:(NSString *)inText
{
    MCLMessage *message = [[MCLMessage alloc] init];
    
    message.messageId = inMessageId;
    message.level = inLevel;
    message.userId = inUserId;
    message.username = inUsername;
    message.subject = inSubject;
    message.date = inDate;
    message.text = inText;
    
    return message;
}

@end
