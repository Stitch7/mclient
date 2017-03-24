//
//  MCLNotificationManager.m
//  mclient
//
//  Created by Christopher Reitz on 11/03/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import "MCLNotificationManager.h"
#import "MCLNotificationHistory.h"

@implementation MCLNotificationManager

#pragma mark - Singleton Methods

+ (id)sharedNotificationManager
{
    static MCLNotificationManager *sharedNotificationManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedNotificationManager = [[self alloc] init];
        [sharedNotificationManager initialize];
    });

    return sharedNotificationManager;
}

- (void)initialize
{
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

#pragma mark - Public Methods

- (void)sendLocalNotificationForResponse:(MCLResponse *)response
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"Response from %@:\n%@", nil), response.username, response.subject];
    notification.soundName = @"zelda1.caf";

    UIApplication *application = [UIApplication sharedApplication];
    [application presentLocalNotificationNow:notification];
}

@end
