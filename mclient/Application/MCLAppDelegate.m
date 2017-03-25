//
//  MCLAppDelegate.m
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLAppDelegate.h"
#import "UIApplication+Additions.h"
#import "MCLThemeManager.h"
#import "MCLResponse.h"
#import "MCLMessageResponsesClient.h"
#import "MCLNotificationHistory.h"


@implementation MCLAppDelegate

@synthesize notificationAlert = _notificationAlert;

# pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[MCLThemeManager sharedManager] loadTheme];
    self.notificationManager = [MCLNotificationManager sharedNotificationManager];

    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[MCLThemeManager sharedManager] loadTheme];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    __block UIBackgroundFetchResult result = UIBackgroundFetchResultNoData;
    MCLMessageResponsesClient *messageResponsesClient = [MCLMessageResponsesClient sharedClient];
    MCLNotificationHistory *notificationHistory = [MCLNotificationHistory sharedNotificationHistory];
    [messageResponsesClient loadDataWithCompletion:^(NSDictionary *responses, NSArray *sectionKeys, NSDictionary *sectionTitles) {
        if ([messageResponsesClient numberOfUnreadResponses] > 0) {
            result = UIBackgroundFetchResultNewData;
            for (MCLResponse *response in [messageResponsesClient unreadResponses]) {
                if ([notificationHistory responseWasAlreadyPresented:response]) {
                    continue;
                }

                [self.notificationManager sendLocalNotificationForResponse:response];
                [notificationHistory addResponse:response];
            }
        }
        completionHandler(result);
    }];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    if ([application applicationState] == UIApplicationStateActive) {
        [self presentNotificationWhileActive:notification];
    }
}

- (void)presentNotificationWhileActive:(UILocalNotification *)notification
{
    if (!_notificationAlert) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [self setNotificationAlert:alert];
    }

    if (!_notificationSound) {
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"Notification" ofType:@"wav"];
        NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &_notificationSound);
    }

    [_notificationAlert setTitle:[notification alertBody]];

    AudioServicesPlaySystemSound(_notificationSound);
    [_notificationAlert show];
}

@end
