//
//  MCLAppDelegate.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLAppDelegate.h"

#import "MCLAppDependencyBag.h"
#import "MCLThemeManager.h"
#import "MCLNotificationManager.h"


@implementation MCLAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.bag = [[MCLAppDependencyBag alloc] init];
    [self.bag launchRootWindow:^(UIWindow *window) {
        self.window = window;
    }];

    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self.bag.themeManager loadTheme];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self.bag.notificationManager notificateAboutNewResponsesWithCompletionHandler:completionHandler];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [self.bag.notificationManager handleReceivedNotification:notification];
}

@end
