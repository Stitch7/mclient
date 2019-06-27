//
//  MCLResponse.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@interface MCLResponse : NSObject

@property (strong) NSNumber *boardId;
@property (strong) NSNumber *threadId;
@property (strong) NSString *threadSubject;
@property (strong) NSNumber *messageId;
@property (strong) NSString *subject;
@property (strong) NSString *username;
@property (strong) NSDate *date;
@property (assign, nonatomic, getter=isRead) BOOL read;
@property (nonatomic, assign, getter=isTemporaryRead) BOOL tempRead;
@property (nonatomic, readonly) NSDictionary *propertyList;

+ (MCLResponse *)responseWithBoardId:(NSNumber *)inBoardId
                            threadId:(NSNumber *)inThreadId
                       threadSubject:(NSString *)inThreadSubject
                           messageId:(NSNumber *)inMessageId
                             subject:(NSString *)inSubject
                            username:(NSString *)inUsername
                                date:(NSDate *)inDate
                                read:(BOOL)inRead;

+ (MCLResponse *)responseWithPropertyList:(NSDictionary *)propertyList;

@end
