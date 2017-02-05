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
@property (assign, nonatomic, getter=isRead) BOOL read;
@property (strong) NSNumber *level;
@property (strong) NSNumber *userId;
@property (assign, nonatomic, getter=isMod) BOOL mod;
@property (strong) NSString *username;
@property (strong) NSString *subject;
@property (strong) NSDate *date;
@property (strong) NSString *text;
@property (strong) NSString *textHtml;
@property (strong) NSString *textHtmlWithImages;
@property (assign, nonatomic) BOOL notification;

+ (MCLMessage *)messageWithId:(NSNumber *)inMessageId
                         read:(BOOL)inRead
                        level:(NSNumber *)inLevel
                          mod:(BOOL)inMod
                     username:(NSString *)inUsername
                      subject:(NSString *)inSubject
                         date:(NSDate *)inDate;

@end
