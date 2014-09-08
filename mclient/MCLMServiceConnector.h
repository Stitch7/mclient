//
//  MCLMServiceConnector.h
//  mclient
//
//  Created by Christopher Reitz on 02.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCLMServiceConnector : NSObject

- (BOOL)testLoginWIthUsername:(NSString *)inUsername
                     password:(NSString *)inPassword;

- (NSInteger)notificationStatusForMessageId:(NSNumber *)inMessageId
                                    boardId:(NSNumber *)inBoardId
                                   username:(NSString *)inUsername
                                   password:(NSString *)inPassword;

- (NSInteger)notificationForMessageId:(NSNumber *)inMessageId
                              boardId:(NSNumber *)inBoardId
                             username:(NSString *)inUsername
                             password:(NSString *)inPassword;

- (NSInteger)quoteForMessageId:(NSNumber *)inMessageId
                       boardId:(NSNumber *)inBoardId;

- (BOOL)postThreadToBoardId:(NSNumber *)inBoardId
                    subject:(NSString *)inSubject
                       text:(NSString *)inText
                   username:(NSString *)inUsername
                   password:(NSString *)inPassword
               notification:(NSNumber *)inNotification;

- (BOOL)postReplyToMessageId:(NSNumber *)inMessageId
                     boardId:(NSNumber *)inBoardId
                     subject:(NSString *)inSubject
                        text:(NSString *)inText
                    username:(NSString *)inUsername
                    password:(NSString *)inPassword
                notification:(NSNumber *)inNotification;

- (BOOL)postEditToMessageId:(NSNumber *)inMessageId
                    boardId:(NSNumber *)inBoardId
                    subject:(NSString *)inSubject
                       text:(NSString *)inText
                   username:(NSString *)inUsername
                   password:(NSString *)inPassword;

@end
