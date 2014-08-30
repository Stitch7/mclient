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
@property (strong) NSString *author;
@property (strong) NSString *subject;
@property (strong) NSString *date;
@property (assign) int answerCount;
@property (strong) NSString *answerDate;

+ (id)threadWithId:(NSNumber *)inThreadId messageId:(NSNumber *)inMessageId sticky:(BOOL)inSticky closed:(BOOL)inClosed mod:(BOOL)inMod author:(NSString *)inAuthor subject:(NSString *)inSubject date:(NSString *)inDate answerCount:(int)inAnswerCount answerDate:(NSString *)inAnswerDate;

@end
