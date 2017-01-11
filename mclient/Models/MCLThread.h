//
//  MCLThread.h
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCLThread : NSObject

@property (strong) NSNumber *threadId;
@property (strong) NSNumber *messageId;
@property (nonatomic, assign, getter=isSticky) BOOL sticky;
@property (nonatomic, assign, getter=isClosed) BOOL closed;
@property (nonatomic, assign, getter=isMod) BOOL mod;
@property (strong) NSString *username;
@property (strong) NSString *subject;
@property (strong) NSDate *date;
@property (strong) NSNumber *messageCount;
@property (strong) NSNumber *lastMessageId;
@property (strong) NSDate *lastMessageDate;

+ (MCLThread *)threadWithId:(NSNumber *)inThreadId
                  messageId:(NSNumber *)inMessageId
                     sticky:(BOOL)inSticky
                     closed:(BOOL)inClosed
                        mod:(BOOL)inMod
                   username:(NSString *)inUsername
                    subject:(NSString *)inSubject
                       date:(NSDate *)inDate
                messageCount:(NSNumber *)inMessageCount
                lastMessageId:(NSNumber *)inLastMessageId
                 lastMessageDate:(NSDate *)inLastMessageDate;

@end
