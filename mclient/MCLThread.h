//
//  MCLThread.h
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCLThread : NSObject

@property (assign) int id;
@property (assign) int firstMessageId;
@property (strong) NSString *author;
@property (strong) NSString *subject;
@property (strong) NSString *date;
@property (strong) NSString *answerCount;
@property (strong) NSString *answerDate;

+ (id) threadWithId:(int)inId firstMessageId:(int)inFirstMessageId author:(NSString *)inAuthor subject:(NSString *)inSubject date:(NSString *)inDate answerCount:(NSString *)inAnswerCount answerDate:(NSString *)inAnswerDate;

@end
