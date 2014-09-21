//
//  MCLMessage.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLMessage.h"

@implementation MCLMessage

+ (id)messageWithId:(NSNumber *)inMessageId
              level:(NSUInteger)inLevel
             userId:(NSNumber *)inUserId
                mod:(BOOL)inMod
           username:(NSString *)inUsername
            subject:(NSString *)inSubject
               date:(NSDate *)inDate
               text:(NSString *)inText
           textHtml:(NSString *)inTextHtml
 textHtmlWithImages:(NSString *)inTextHtmlWithImages
{
    MCLMessage *message = [[MCLMessage alloc] init];
    
    message.messageId = inMessageId;
    message.level = inLevel;
    message.userId = inUserId;
    message.username = inUsername;
    message.mod = inMod;
    message.subject = inSubject;
    message.date = inDate;
    message.text = inText;
    message.textHtml = inTextHtml;
    message.textHtmlWithImages = inTextHtmlWithImages;
    
    return message;
}

@end
