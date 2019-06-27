//
//  MCLThread.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLThread.h"

@implementation MCLThread

+ (MCLThread *)threadWithId:(NSNumber *)inThreadId
{
    MCLThread *thread = [[MCLThread alloc] init];

    thread.threadId = inThreadId;

    return thread;
}

+ (MCLThread *)threadWithId:(NSNumber *)inThreadId
                    subject:(NSString *)inSubject
{
    MCLThread *thread = [[MCLThread alloc] init];

    thread.threadId = inThreadId;
    thread.subject = inSubject;

    return thread;
}

+ (MCLThread *)threadWithId:(NSNumber *)inThreadId
                    boardId:(NSNumber *)inBoardId
                  messageId:(NSNumber *)inMessageId
                       read:(BOOL)inRead
                   favorite:(BOOL)inFavorite
                     sticky:(BOOL)inSticky
                     closed:(BOOL)inClosed
                        mod:(BOOL)inMod
                   username:(NSString *)inUsername
                    subject:(NSString *)inSubject
                       date:(NSDate *)inDate
               messagesCount:(NSNumber *)inMessagesCount
               messagesRead:(NSNumber *)inMessagesRead
              lastMessageId:(NSNumber *)inLastMessageId
            lastMessageRead:(BOOL)inLastMessageRead
            lastMessageDate:(NSDate *)inLastMessageDate
{
    MCLThread *thread = [[MCLThread alloc] init];
    
    thread.threadId = inThreadId;
    thread.boardId = inBoardId;
    thread.messageId = inMessageId;
    thread.read = inRead;
    thread.favorite = inFavorite;
    thread.tempRead = inRead;
    thread.sticky = inSticky;
    thread.closed = inClosed;
    thread.mod = inMod;
    thread.username = inUsername;
    thread.subject = inSubject;
    thread.date = inDate;
    thread.messagesCount = inMessagesCount;
    thread.messagesRead = inMessagesRead;
    thread.lastMessageId = inLastMessageId;
    thread.lastMessageRead = inLastMessageRead;
    thread.lastMessageDate = inLastMessageDate;
    
    return thread;
}

+ (MCLThread *)threadFromJSON:(NSDictionary *)json
{
    NSDateFormatter *dateFormatterForInput = [[NSDateFormatter alloc] init];
    [dateFormatterForInput setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatterForInput setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

    NSNumber *threadId = [json objectForKey:@"id"];
    NSNumber *boardId = [json objectForKey:@"boardId"];
    NSNumber *messageId = [json objectForKey:@"messageId"];
    id isRead = [json objectForKey:@"isRead"];
    BOOL read = isRead != (id)[NSNull null] ? [isRead boolValue] : YES;
    id isFavorite = [json objectForKey:@"isFavorite"];
    BOOL favorite = isFavorite != (id)[NSNull null] ? [isFavorite boolValue] : NO;
    BOOL sticky = [[json objectForKey:@"sticky"] boolValue];
    BOOL closed = [[json objectForKey:@"closed"] boolValue];
    BOOL mod = [[json objectForKey:@"mod"] boolValue];
    NSString *username = [json objectForKey:@"username"];
    NSString *subject = [json objectForKey:@"subject"];
    NSDate *date = [dateFormatterForInput dateFromString:[json objectForKey:@"date"]];
    NSNumber *messagesCount = [json objectForKey:@"messagesCount"];
    id messagesReadOpt = [json objectForKey:@"messagesRead"];
    NSNumber *messagesRead = messagesReadOpt != (id)[NSNull null] ? messagesReadOpt : messagesCount;
    NSNumber *lastMessageId = [json objectForKey:@"lastMessageId"];
    id lastMessageReadOpt = [json objectForKey:@"lastMessageIsRead"];
    BOOL lastMessageRead = lastMessageReadOpt != (id)[NSNull null] ? [lastMessageReadOpt boolValue] : YES;
    NSDate *lastMessageDate = [dateFormatterForInput dateFromString:[json objectForKey:@"lastMessageDate"]];

    return [MCLThread threadWithId:threadId
                           boardId:boardId
                         messageId:messageId
                              read:read
                          favorite:favorite
                            sticky:sticky
                            closed:closed
                               mod:mod
                          username:username
                           subject:subject
                              date:date
                     messagesCount:messagesCount
                      messagesRead:messagesRead
                     lastMessageId:lastMessageId
                   lastMessageRead:lastMessageRead
                   lastMessageDate:lastMessageDate];
}

@end
