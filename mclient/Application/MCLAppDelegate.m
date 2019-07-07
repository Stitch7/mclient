//
//  MCLAppDelegate.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLAppDelegate.h"

#import "MCLAppDependencyBag.h"
#import "MCLThemeManager.h"
#import "MCLNotificationManager.h"
#import "MCLKeyboardShortcutManager.h"


@interface MCLAppDelegate ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;

@end

@implementation MCLAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.bag = [[MCLAppDependencyBag alloc] init];
    [self.bag.router launchRootWindow:^(UIWindow *window) {
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
    [self.bag.notificationManager runForNewNotificationsWithCompletionHandler:completionHandler];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [self.bag.notificationManager handleReceivedNotification:notification];
}

#pragma mark - UIResponder

- (UIResponder *)nextResponder
{
    return self.bag.keyboardShortcutManager;
}

@end
