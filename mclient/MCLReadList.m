//
//  MCLReadList.m
//  mclient
//
//  Created by Christopher Reitz on 31.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLReadList.h"

@interface MCLReadList()

@property (strong) NSMutableArray *messages;

@end

@implementation MCLReadList

- (id)init
{
    if (self = [super init]) {
        self.messages = [[NSMutableArray alloc] initWithContentsOfFile:[self fileName]];
        if (self.messages == nil) {
            self.messages = [[NSMutableArray alloc] init];
        }
    }
    
    return self;
}

- (void)addMessageId:(NSNumber *)messageId
{
    [self.messages addObject:messageId];
    [self.messages writeToFile:[self fileName] atomically:YES];
}

- (BOOL)messageIdIsRead:(NSNumber *)messageId
{
    return [self.messages containsObject:messageId];
}

- (NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fileName = [documentsDirectory stringByAppendingPathComponent:@"readlist.xml"];
    
    return fileName;
}

@end
