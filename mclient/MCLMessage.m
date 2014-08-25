//
//  MCLMessage.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLMessage.h"

@implementation MCLMessage

+ (id) messageWithId:(int)inId level:(int)inLevel author:(NSString *)inAuthor subject:(NSString *)inSubject date:(NSString *)inDate text:(NSString *)inText
{
    MCLMessage *message = [[MCLMessage alloc] init];
    
    message.id = inId;
    message.level = inLevel;
    message.author = inAuthor;
    message.subject = inSubject;
    message.date = inDate;
    message.text = inText;
    
    return message;
}

@end
