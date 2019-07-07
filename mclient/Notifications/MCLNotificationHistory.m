//
//  MCLNotificationHistory.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLNotificationHistory.h"
#import "UIApplication+Additions.h"
#import "MCLResponse.h"

#define kUserDefaultsPoolKey @"MCLNotificationHistoryPool"

@interface MCLNotificationHistory()

@property (strong, nonatomic) NSMutableArray *pool;
@property (strong, nonatomic) NSUserDefaults *userDefaults;

@end


@implementation MCLNotificationHistory

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

- (void)addResponse:(MCLResponse *)response
{
    if ([self.pool containsObject:response.messageId]) {
        return;
    }

    [self.pool addObject:response.messageId];
}

- (void)removeResponse:(MCLResponse *)response
{
    [self removeMessageId:response.messageId];
}

- (void)removeMessageId:(NSNumber *)messageId
{
    if ([self.pool containsObject:messageId]) {
        [self.pool removeObject:messageId];
        [self persist];
        [[UIApplication sharedApplication] decrementApplicationIconBadgeNumber];
    }
}

- (BOOL)responseWasAlreadyPresented:(MCLResponse *)response
{
    return [self.pool containsObject:response.messageId];
}

- (void)persist
{
    [self.userDefaults setObject:[self.pool copy] forKey:kUserDefaultsPoolKey];
    [self.userDefaults synchronize];
}

@end
