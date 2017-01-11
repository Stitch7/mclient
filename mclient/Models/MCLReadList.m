//
//  MCLReadList.m
//  mclient
//
//  Created by Christopher Reitz on 31.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLReadList.h"
#import "MCLThread.h"

#define kUserDefaultsKey @"MCLReadList"
#define kOldUserDefaultsKey @"readList"  // TODO: Remove this is in next release

@interface MCLReadList()

@property (strong, nonatomic) NSMutableDictionary *pool;
@property (strong, nonatomic) NSUserDefaults *userDefaults;

@end

@implementation MCLReadList

- (id)init
{
    if (self = [super init]) {
        self.userDefaults = [NSUserDefaults standardUserDefaults];

        [self.userDefaults removeObjectForKey:kOldUserDefaultsKey];
        self.pool = [[self.userDefaults objectForKey:kUserDefaultsKey] mutableCopy];
        if (self.pool == nil) {
            self.pool = [[NSMutableDictionary alloc] init];
        }
    }

    return self;
}

- (void)addMessageId:(NSNumber *)messageId fromThread:(MCLThread *)thread
{
    if ([self messageIdIsRead:messageId fromThread:thread]) {
        return;
    }

    NSMutableArray *messages = [NSMutableArray arrayWithArray: [self.pool objectForKey:[thread.threadId stringValue]]];
    if (!messages) {
        messages = [[NSMutableArray alloc] init];
    }
    [messages addObject:messageId];

    [self.pool setObject:messages forKey:[thread.threadId stringValue]];
    [self.userDefaults setObject:self.pool forKey:kUserDefaultsKey];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.userDefaults synchronize];
    });
}

- (void)addMessages:(NSArray *)messages fromThread:(MCLThread *)thread
{
    [self.pool setObject:messages forKey:[thread.threadId stringValue]];
    [self.userDefaults setObject:self.pool forKey:kUserDefaultsKey];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.userDefaults synchronize];
    });
}

- (BOOL)messageIdIsRead:(NSNumber *)messageId fromThread:(MCLThread *)thread
{
    NSArray *messages = [self.pool objectForKey:[thread.threadId stringValue]];
    return messages ? [messages containsObject:messageId] : false;
}

- (NSArray *)messagesFromThread:(MCLThread *)thread
{
    return [self.pool objectForKey:[thread.threadId stringValue]];
}

- (NSNumber *)readMessagesCountFromThread:(MCLThread *)thread
{
    return @([[self messagesFromThread:thread] count]);
}

@end
