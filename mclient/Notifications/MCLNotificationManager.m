//
//  MCLNotificationManager.m
//  mclient
//
//  Created by Christopher Reitz on 11/03/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import "MCLNotificationManager.h"


@implementation MCLNotificationManager

#pragma mark - Singleton Methods -

+ (id)sharedNotificationManager
{
    static MCLNotificationManager *sharedNotificationManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedNotificationManager = [[self alloc] init];
    });

    return sharedNotificationManager;
}

- (void)initialize
{
    self.notificationHistory = [MCLNotificationHistory sharedNotificationHistory];
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

#pragma mark - Public Methods -

- (void)sendLocalNotificationForResponse:(MCLResponse *)response
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"Antwort von %@:\n%@", nil), response.username, response.subject];
    notification.soundName = UILocalNotificationDefaultSoundName;

    UIApplication *application = [UIApplication sharedApplication];
    [application presentLocalNotificationNow:notification];

    [self.notificationHistory addResponse:response];
}

@end
