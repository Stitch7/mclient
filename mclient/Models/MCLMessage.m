//
//  MCLMessage.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLMessage.h"

@implementation MCLMessage

+ (MCLMessage *)messageWithId:(NSNumber *)inMessageId
                         read:(BOOL)inRead
                        level:(NSNumber *)inLevel
                          mod:(BOOL)inMod
                     username:(NSString *)inUsername
                      subject:(NSString *)inSubject
                         date:(NSDate *)inDate
{
    MCLMessage *message = [[MCLMessage alloc] init];
    
    message.messageId = inMessageId;
    message.read = inRead;
    message.level = inLevel;
    message.username = inUsername;
    message.mod = inMod;
    message.subject = inSubject;
    message.date = inDate;

    return message;
}

@end
