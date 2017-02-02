//
//  MCLMServiceConnector.h
//  mclient
//
//  Created by Christopher Reitz on 02.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCLMServiceConnector : NSObject

+ (id)sharedConnector;

- (void)testLoginWithUsername:(NSString *)inUsername
                     password:(NSString *)inPassword
                        error:(NSError **)errorPtr;

- (NSDictionary *)boards:(NSError **)errorPtr;

- (NSDictionary *)threadsFromBoardId:(NSNumber *)inBoardId
                               login:(NSDictionary *)loginData
                               error:(NSError **)errorPtr;

- (NSDictionary *)threadWithId:(NSNumber *)inThreadId
                   fromBoardId:(NSNumber *)inBoardId
                         login:(NSDictionary *)loginData
                         error:(NSError **)errorPtr;

- (NSDictionary *)markAsReadThreadWithId:(NSNumber *)inThreadId
                   fromBoardId:(NSNumber *)inBoardId
                         login:(NSDictionary *)loginData
                         error:(NSError **)errorPtr;

- (void)importReadList:(NSDictionary *)inReadList
                 login:(NSDictionary *)loginData
                 error:(NSError **)errorPtr;

- (NSDictionary *)messageWithId:(NSNumber *)inMessageId
                    fromBoardId:(NSNumber *)inBoardId
                    andThreadId:(NSNumber *)inThreadId
                          login:(NSDictionary *)loginData
                          error:(NSError **)errorPtr;

- (NSDictionary *)quoteMessageWithId:(NSNumber *)inMessageId
                         fromBoardId:(NSNumber *)inBoardId
                               error:(NSError **)errorPtr;

- (NSDictionary *)userWithId:(NSNumber *)inUserId
                       error:(NSError **)errorPtr;

- (BOOL)notificationStatusForMessageId:(NSNumber *)inMessageId
                               boardId:(NSNumber *)inBoardId
                              username:(NSString *)inUsername
                              password:(NSString *)inPassword
                                 error:(NSError **)errorPtr;

- (void)notificationForMessageId:(NSNumber *)inMessageId
                         boardId:(NSNumber *)inBoardId
                        username:(NSString *)inUsername
                        password:(NSString *)inPassword
                           error:(NSError **)errorPtr;

- (NSDictionary *)messagePreviewForBoardId:(NSNumber *)inBoardId
                                      text:(NSString *)inText
                                     error:(NSError **)errorPtr;

- (void)postThreadToBoardId:(NSNumber *)inBoardId
                    subject:(NSString *)inSubject
                       text:(NSString *)inText
                   username:(NSString *)inUsername
                   password:(NSString *)inPassword
               notification:(BOOL)inNotification
                      error:(NSError **)errorPtr;

- (void)postReplyToMessageId:(NSNumber *)inMessageId
                     boardId:(NSNumber *)inBoardId
                     threadId:(NSNumber *)inThreadId
                     subject:(NSString *)inSubject
                        text:(NSString *)inText
                    username:(NSString *)inUsername
                    password:(NSString *)inPassword
                notification:(BOOL)inNotification
                       error:(NSError **)errorPtr;

- (void)postEditToMessageId:(NSNumber *)inMessageId
                    boardId:(NSNumber *)inBoardId
                   threadId:(NSNumber *)inThreadId
                    subject:(NSString *)inSubject
                       text:(NSString *)inText
                   username:(NSString *)inUsername
                   password:(NSString *)inPassword
                      error:(NSError **)errorPtr;

- (NSDictionary *)searchThreadsOnBoard:(NSNumber *)inBoardId
                            withPhrase:(NSString *)inPhrase
                                 login:(NSDictionary *)loginData
                                 error:(NSError **)errorPtr;

@end
