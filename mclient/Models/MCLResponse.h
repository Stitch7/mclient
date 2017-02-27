//
//  MCLResponse.h
//  mclient
//
//  Created by Christopher Reitz on 27/02/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

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

+ (MCLResponse *)responseWithBoardId:(NSNumber *)inBoardId
                            threadId:(NSNumber *)inThreadId
                       threadSubject:(NSString *)inThreadSubject
                           messageId:(NSNumber *)inMessageId
                             subject:(NSString *)inSubject
                            username:(NSString *)inUsername
                                date:(NSDate *)inDate
                                read:(BOOL)inRead;

@end
