//
//  MCLThread.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLBoard;

@interface MCLThread : NSObject

@property (strong, nonatomic) MCLBoard *board;

@property (strong) NSNumber *threadId;
@property (strong) NSNumber *boardId;
@property (strong) NSNumber *messageId;
@property (nonatomic, assign, getter=isRead) BOOL read;
@property (nonatomic, assign, getter=isFavorite) BOOL favorite;
@property (nonatomic, assign, getter=isTemporaryRead) BOOL tempRead;
@property (nonatomic, assign, getter=isSticky) BOOL sticky;
@property (nonatomic, assign, getter=isClosed) BOOL closed;
@property (nonatomic, assign, getter=isMod) BOOL mod;
@property (strong) NSString *username;
@property (strong) NSString *subject;
@property (strong) NSDate *date;
@property (strong) NSNumber *messagesCount;
@property (strong) NSNumber *messagesRead;
@property (strong) NSNumber *lastMessageId;
@property (nonatomic, assign, getter=lastMessageIsRead) BOOL lastMessageRead;
@property (strong) NSDate *lastMessageDate;

+ (MCLThread *)threadWithId:(NSNumber *)inThreadId;

+ (MCLThread *)threadWithId:(NSNumber *)inThreadId
                    subject:(NSString *)inSubject;

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
            lastMessageDate:(NSDate *)inLastMessageDate;

+ (MCLThread *)threadFromJSON:(NSDictionary *)json;

@end
