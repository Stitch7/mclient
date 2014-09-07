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
@property (assign) NSUInteger level;
@property (strong) NSNumber *userId;
@property (strong) NSString *username;
@property (strong) NSString *subject;
@property (strong) NSString *date;
@property (strong) NSString *text;

+ (id)messageWithId:(NSNumber *)inMessageId level:(NSUInteger)inLevel userId:(NSNumber *)inUserId username:(NSString *)inUsername subject:(NSString *)inSubject date:(NSString *)inDate text:(NSString *)inText;

@end
