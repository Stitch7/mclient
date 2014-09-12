//
//  MCLMServiceConnector.h
//  mclient
//
//  Created by Christopher Reitz on 02.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCLMServiceConnector : NSObject

- (NSArray *)errorMessages;

- (BOOL)testLoginWIthUsername:(NSString *)inUsername
                     password:(NSString *)inPassword
                        error:(NSError **)errorPtr;

- (BOOL)notificationStatusForMessageId:(NSNumber *)inMessageId
                                    boardId:(NSNumber *)inBoardId
                                   username:(NSString *)inUsername
                                   password:(NSString *)inPassword
                                      error:(NSError **)errorPtr;

- (BOOL)notificationForMessageId:(NSNumber *)inMessageId
                              boardId:(NSNumber *)inBoardId
                             username:(NSString *)inUsername
                             password:(NSString *)inPassword
                                error:(NSError **)errorPtr;

- (BOOL)quoteForMessageId:(NSNumber *)inMessageId
                       boardId:(NSNumber *)inBoardId
                         error:(NSError **)errorPtr;

- (BOOL)postThreadToBoardId:(NSNumber *)inBoardId
                    subject:(NSString *)inSubject
                       text:(NSString *)inText
                   username:(NSString *)inUsername
                   password:(NSString *)inPassword
                      error:(NSError **)errorPtr;

- (BOOL)postReplyToMessageId:(NSNumber *)inMessageId
                     boardId:(NSNumber *)inBoardId
                     subject:(NSString *)inSubject
                        text:(NSString *)inText
                    username:(NSString *)inUsername
                    password:(NSString *)inPassword
                       error:(NSError **)errorPtr;

- (BOOL)postEditToMessageId:(NSNumber *)inMessageId
                    boardId:(NSNumber *)inBoardId
                    subject:(NSString *)inSubject
                       text:(NSString *)inText
                   username:(NSString *)inUsername
                   password:(NSString *)inPassword
                      error:(NSError **)errorPtr;

- (NSData *)searchOnBoard:(NSNumber *)inBoardId
               withPhrase:(NSString *)inPhrase
                    error:(NSError **)errorPtr;

@end
