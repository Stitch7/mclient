//
//  MCLDraft.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@interface MCLDraft : NSObject <NSCoding>

@property (assign) NSUInteger type;
@property (strong) NSString *boardName;
@property (strong) NSNumber *boardId;
@property (strong) NSNumber *threadId;
@property (strong) NSNumber *messageId;
@property (strong) NSString *originalSubject;
@property (strong) NSString *subject;
@property (strong) NSString *text;
@property (strong) NSDate *date;

@end
