//
//  MCLMessage.h
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCLMessage : NSObject

@property (strong) NSNumber *messageId;
@property (strong) NSNumber *level;
@property (strong) NSNumber *userId;
@property (assign, nonatomic, getter=isMod) BOOL mod;
@property (strong) NSString *username;
@property (strong) NSString *subject;
@property (strong) NSDate *date;
@property (strong) NSString *text;
@property (strong) NSString *textHtml;
@property (strong) NSString *textHtmlWithImages;

+ (id)messageWithId:(NSNumber *)inMessageId
              level:(NSNumber *)inLevel
             userId:(NSNumber *)inUserId
                mod:(BOOL)inMod
           username:(NSString *)inUsername
            subject:(NSString *)inSubject
               date:(NSDate *)inDate
               text:(NSString *)inText
           textHtml:(NSString *)inTextHtml
textHtmlWithImages:(NSString *)inTextHtmlWithImages;

@end
