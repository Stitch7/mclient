//
//  MCLReadList.m
//  mclient
//
//  Created by Christopher Reitz on 31.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLReadList.h"

@interface MCLReadList()

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSUserDefaults *userDefaults;

@end

@implementation MCLReadList

- (id)init
{
    if (self = [super init]) {
        self.userDefaults = [NSUserDefaults standardUserDefaults];
        self.messages = [[self.userDefaults objectForKey:@"readList"] mutableCopy];
        if (self.messages == nil) {
            self.messages = [[NSMutableArray alloc] init];
        }
    }
    
    return self;
}

- (void)addMessageId:(NSNumber *)messageId
{
    if ( ! [self messageIdIsRead:messageId]) {
        [self.messages addObject:messageId];
        [self.userDefaults setObject:self.messages forKey:@"readList"];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.userDefaults synchronize];
//            NSLog(@"%@ count: %lu", self.messages, (unsigned long)[self.messages count]);
        });
    }
}

- (BOOL)messageIdIsRead:(NSNumber *)messageId
{
    return [self.messages containsObject:messageId];
}

@end
