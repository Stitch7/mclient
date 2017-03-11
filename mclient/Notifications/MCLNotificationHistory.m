//
//  MCLNotificationHistory.m
//  mclient
//
//  Created by Christopher Reitz on 11/03/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import "MCLNotificationHistory.h"
#import "UIApplication+Additions.h"

#define kUserDefaultsPoolKey @"MCLNotificationHistoryPool"

@interface MCLNotificationHistory()

@property (strong, nonatomic) NSMutableArray *pool;
@property (strong, nonatomic) NSUserDefaults *userDefaults;

@end


@implementation MCLNotificationHistory

#pragma mark - Singleton Methods -

+ (id)sharedNotificationHistory
{
    static MCLNotificationHistory *sharedNotificationHistory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedNotificationHistory = [[self alloc] init];

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableArray *pool;
//        pool = [userDefaults objectForKey:kUserDefaultsPoolKey];
        if (!pool) {
            pool = [NSMutableArray array];
        }

        [sharedNotificationHistory setUserDefaults:userDefaults];
        [sharedNotificationHistory setPool:pool];
    });

    return sharedNotificationHistory;
}

#pragma mark - Public Methods -

- (void)addResponse:(MCLResponse *)response
{
    if (![self.pool containsObject:response]) {
        [self.pool addObject:response.messageId];
        [self.userDefaults setObject:self.pool forKey:kUserDefaultsPoolKey];
        [[UIApplication sharedApplication] incrementApplicationIconBadgeNumber];
    }
}

- (void)removeResponse:(MCLResponse *)response
{
    [self removeMessageId:response.messageId];
}

- (void)removeMessageId:(NSNumber *)messageId
{
    if ([self.pool containsObject:messageId]) {
        [self.pool removeObject:messageId];
        [self.userDefaults setObject:self.pool forKey:kUserDefaultsPoolKey];
        [[UIApplication sharedApplication] decrementApplicationIconBadgeNumber];
    }
}

- (BOOL)responseWasNotPresented:(MCLResponse *)response
{
    return ![self.pool containsObject:response.messageId];
}

@end
