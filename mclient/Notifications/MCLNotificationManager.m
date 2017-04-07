//
//  MCLNotificationManager.m
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLNotificationManager.h"

#import "MCLDependencyBag.h"
#import "MCLSettings.h"
#import "MCLNotificationHistory.h"
#import "MCLMessageResponsesRequest.h"

@interface MCLNotificationManager ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;

@end

@implementation MCLNotificationManager

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;
    self.history = [[MCLNotificationHistory alloc] init];

    if ([self backgroundNotificationsEnabled]) {
        [self registerBackgroundNotifications];
    } else {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    }

    return self;
}

#pragma mark - Public Methods

- (void)registerBackgroundNotifications
{
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

- (BOOL)backgroundNotificationsRegistered
{
    UIUserNotificationSettings *userNotificationSettings = [UIApplication sharedApplication].currentUserNotificationSettings;
    return userNotificationSettings.types != UIUserNotificationTypeNone;
}

- (BOOL)backgroundNotificationsEnabled
{
    return [self.bag.settings integerForSetting:MCLSettingThreadView] ?: NO;
}

- (void)sendLocalNotificationForResponse:(MCLResponse *)response
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertAction = NSLocalizedString(@"Open", nil);
    notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"Response from %@:\n%@", nil), response.username, response.subject];
    notification.soundName = @"zelda1.caf";

    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)notificateAboutNewResponsesWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    MCLMessageResponsesRequest *messageResponsesRequest = [[MCLMessageResponsesRequest alloc] initWithBag:self.bag];
    [messageResponsesRequest loadUnreadResponsesWithCompletion:^(NSError *error, NSArray *unreadResponses) {
        if (!error && [unreadResponses count] > 0) {
            for (MCLResponse *response in unreadResponses) {
                if ([self.history responseWasAlreadyPresented:response]) {
                    continue;
                }

                [self sendLocalNotificationForResponse:response];
                [self.history addResponse:response];
            }
            [self.history persist];
        }
        // We cheat a little to be called as often as possible
        completionHandler(UIBackgroundFetchResultNewData);
    }];
}

@end
