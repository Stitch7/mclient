//
//  MCLDraft.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLDraft.h"

@implementation MCLDraft

@synthesize type;
@synthesize boardId;
@synthesize boardName;
@synthesize threadId;
@synthesize messageId;
@synthesize originalSubject;
@synthesize subject;
@synthesize text;
@synthesize date;

# pragma mark - NSCoding

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder
{
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:self.type] forKey:@"type"];
    [aCoder encodeObject:boardId forKey:@"boardId"];
    [aCoder encodeObject:boardName forKey:@"boardName"];
    [aCoder encodeObject:threadId forKey:@"threadId"];
    [aCoder encodeObject:messageId forKey:@"messageId"];
    [aCoder encodeObject:originalSubject forKey:@"originalSubject"];
    [aCoder encodeObject:subject forKey:@"subject"];
    [aCoder encodeObject:text forKey:@"text"];
    [aCoder encodeObject:date forKey:@"date"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder
{
    self = [super init];
    if (!self) return nil;

    self.type = [[aDecoder decodeObjectForKey:@"type"] intValue];
    self.boardId = [aDecoder decodeObjectForKey:@"boardId"];
    self.boardName = [aDecoder decodeObjectForKey:@"boardName"];
    self.threadId = [aDecoder decodeObjectForKey:@"threadId"];
    self.messageId = [aDecoder decodeObjectForKey:@"messageId"];
    self.originalSubject = [aDecoder decodeObjectForKey:@"originalSubject"];
    self.subject = [aDecoder decodeObjectForKey:@"subject"];
    self.text = [aDecoder decodeObjectForKey:@"text"];
    self.date = [aDecoder decodeObjectForKey:@"date"];

    return self;
}

@end
