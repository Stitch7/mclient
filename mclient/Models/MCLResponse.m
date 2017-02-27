//
//  MCLResponse.m
//  mclient
//
//  Created by Christopher Reitz on 27/02/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import "MCLResponse.h"

@implementation MCLResponse

+ (MCLResponse *)responseWithBoardId:(NSNumber *)inBoardId
                            threadId:(NSNumber *)inThreadId
                       threadSubject:(NSString *)inThreadSubject
                           messageId:(NSNumber *)inMessageId
                             subject:(NSString *)inSubject
                            username:(NSString *)inUsername
                                date:(NSDate *)inDate
                                read:(BOOL)inRead
{
    MCLResponse *response = [[MCLResponse alloc] init];

    response.boardId = inBoardId;
    response.threadId = inThreadId;
    response.threadSubject = inThreadSubject;
    response.messageId = inMessageId;
    response.subject = inSubject;
    response.username = inUsername;
    response.date = inDate;
    response.read = inRead;
    response.tempRead = inRead;

    return response;
}

@end
