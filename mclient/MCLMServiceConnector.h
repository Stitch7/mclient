//
//  MCLMServiceConnector.h
//  mclient
//
//  Created by Christopher Reitz on 02.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCLMServiceConnector : NSObject

@property(strong, nonatomic) NSDictionary *errorMessages;

+ (id)sharedConnector;

- (NSDictionary *)boards:(NSError **)errorPtr;

- (NSDictionary *)threadsFromBoardId:(NSNumber *)inBoardId
                               error:(NSError **)errorPtr;

- (NSDictionary *)threadWithId:(NSNumber *)inThreadId
                   fromBoardId:(NSNumber *)inBoardId
                         error:(NSError **)errorPtr;

- (NSDictionary *)messageWithId:(NSNumber *)inMessageId
                    fromBoardId:(NSNumber *)inBoardId
                          error:(NSError **)errorPtr;

- (NSDictionary *)quoteMessageWithId:(NSNumber *)inMessageId
                         fromBoardId:(NSNumber *)inBoardId
                               error:(NSError **)errorPtr;

- (NSDictionary *)userWithId:(NSNumber *)inUserId
                       error:(NSError **)errorPtr;


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

- (NSDictionary *)messagePreviewForBoardId:(NSNumber *)inBoardId
                                      text:(NSString *)inText
                                     error:(NSError **)errorPtr;

- (BOOL)postThreadToBoardId:(NSNumber *)inBoardId
                    subject:(NSString *)inSubject
                       text:(NSString *)inText
                   username:(NSString *)inUsername
                   password:(NSString *)inPassword
               notification:(BOOL)inNotification
                      error:(NSError **)errorPtr;

- (BOOL)postReplyToMessageId:(NSNumber *)inMessageId
                     boardId:(NSNumber *)inBoardId
                     subject:(NSString *)inSubject
                        text:(NSString *)inText
                    username:(NSString *)inUsername
                    password:(NSString *)inPassword
                notification:(BOOL)inNotification
                       error:(NSError **)errorPtr;

- (BOOL)postEditToMessageId:(NSNumber *)inMessageId
                    boardId:(NSNumber *)inBoardId
                    subject:(NSString *)inSubject
                       text:(NSString *)inText
                   username:(NSString *)inUsername
                   password:(NSString *)inPassword
                      error:(NSError **)errorPtr;

- (NSDictionary *)searchThreadsOnBoard:(NSNumber *)inBoardId
                            withPhrase:(NSString *)inPhrase
                                 error:(NSError **)errorPtr;

@end
