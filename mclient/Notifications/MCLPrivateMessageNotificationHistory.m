//
//  MCLPrivateMessageNotificationHistory.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLPrivateMessageNotificationHistory.h"

#import "UIApplication+Additions.h"
#import "MCLPrivateMessage.h"

#define kUserDefaultsPoolKey @"MCLPrivateMessageNotificationHistory"

@interface MCLPrivateMessageNotificationHistory()

@property (strong, nonatomic) NSMutableArray *pool;
@property (strong, nonatomic) NSUserDefaults *userDefaults;

@end


@implementation MCLPrivateMessageNotificationHistory

#pragma mark - Initializers

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    self.userDefaults = [NSUserDefaults standardUserDefaults];
    self.pool = [self.userDefaults mutableArrayValueForKey:kUserDefaultsPoolKey];
    if (!self.pool) {
        self.pool = [NSMutableArray array];
    }

    return self;
}

#pragma mark - Public Methods

- (void)addPrivateMessage:(MCLPrivateMessage *)privateMessage
{
    if ([self.pool containsObject:privateMessage.messageId]) {
        return;
    }

    [self.pool addObject:privateMessage.messageId];
}

- (void)removePrivateMessage:(MCLPrivateMessage *)privateMessage
{
    [self removeMessageId:privateMessage.messageId];
}

- (void)removeMessageId:(NSNumber *)messageId
{
    if ([self.pool containsObject:messageId]) {
        [self.pool removeObject:messageId];
        [self persist];
//        [[UIApplication sharedApplication] decrementApplicationIconBadgeNumber];
    }
}

- (BOOL)privateMessageWasAlreadyPresented:(MCLPrivateMessage *)privateMessage
{
    return [self.pool containsObject:privateMessage.messageId];
}

- (void)persist
{
    [self.userDefaults setObject:[self.pool copy] forKey:kUserDefaultsPoolKey];
    [self.userDefaults synchronize];
}

@end
