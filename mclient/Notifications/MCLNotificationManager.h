//
//  MCLNotificationManager.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;
@class MCLNotificationHistory;
@class MCLPrivateMessageNotificationHistory;
@class MCLResponse;

@interface MCLNotificationManager : NSObject

@property (strong, nonatomic) MCLNotificationHistory *history;
@property (strong, nonatomic) MCLPrivateMessageNotificationHistory *privateMessageHistory;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;

- (void)registerBackgroundNotifications;
- (BOOL)backgroundNotificationsRegistered;
- (BOOL)backgroundNotificationsEnabled;
- (void)sendLocalNotificationForResponse:(MCLResponse *)response;
- (void)runForNewNotificationsWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)handleReceivedNotification:(UILocalNotification *)notification;

@end
