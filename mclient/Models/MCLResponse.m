//
//  MCLResponse.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLResponse.h"

@implementation MCLResponse

#pragma mark - Initializers

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

#pragma mark - Computed properties

- (NSDictionary *)propertyList
{
    return @{@"boardId": self.boardId,
             @"threadId": self.threadId,
             @"threadSubject": self.threadSubject,
             @"messageId": self.messageId,
             @"subject": self.subject,
             @"username": self.username,
             @"date": self.date,
             @"read": [NSNumber numberWithBool:self.read]};
}

@end
