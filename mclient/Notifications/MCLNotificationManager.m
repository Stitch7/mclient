//
//  MCLNotificationManager.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLNotificationManager.h"

#import <AsyncBlockOperation/AsyncBlockOperation.h>

#import "MCLDependencyBag.h"
#import "MCLFeatures.h"
#import "MCLSettings.h"
#import "MCLNotificationHistory.h"
#import "MCLPrivateMessageNotificationHistory.h"
#import "MCLMessageResponsesRequest.h"
#import "MCLPrivateMessage.h"
#import "MCLPrivateMessagesListRequest.h"
#import "MCLPrivateMessagesManager.h"
#import "MCLPrivateMessageConversation.h"
#import "MCLRouter+mainNavigation.h"
#import "MCLRouter+privateMessages.h"
#import "MCLUser.h"
#import "MCLMessage.h"
#import "MCLResponse.h"

static NSString *kQueueOperationsChanged = @"kQueueOperationsChanged";
static NSString *kQueueKeyPath = @"operations";
static NSString *kNotificationTypeResponse = @"NotificationTypeResponse";
static NSString *kNotificationTypePrivateMessage = @"NotificationTypePrivateMessage";

@interface MCLNotificationManager ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) NSOperationQueue *queue;
@property (nonatomic, copy) void (^completionHandler)(UIBackgroundFetchResult);
@property (assign, nonatomic, getter=isRunning) BOOL running;

@end

@implementation MCLNotificationManager

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;
    self.history = [[MCLNotificationHistory alloc] init];
    self.privateMessageHistory = [[MCLPrivateMessageNotificationHistory alloc] init];

    if ([self backgroundNotificationsEnabled]) {
        [self registerBackgroundNotifications];
    } else {
        [self.bag.application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    }

    self.queue = [[NSOperationQueue alloc] init];
    [self.queue addObserver:self forKeyPath:kQueueKeyPath options:0 context:&kQueueOperationsChanged];
    self.running = NO;

    return self;
}

- (void)dealloc
{
    [self.queue removeObserver:self forKeyPath:kQueueKeyPath context:&kQueueOperationsChanged];
}

#pragma mark - Queue observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.queue && [keyPath isEqualToString:kQueueKeyPath] && context == &kQueueOperationsChanged) {
        if ([self.queue.operations count] > 0) {
            return;
        }

        [self callCompletionHandlerOnce];
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

#pragma mark - Completion Handler

- (void)callCompletionHandlerOnce
{
    if (self.completionHandler) {
        // We cheat a little to be called as often as possible
        self.completionHandler(UIBackgroundFetchResultNewData);
        self.completionHandler = nil;
    }
    self.running = NO;
}

#pragma mark - Public Methods

- (void)registerBackgroundNotifications
{
    [self.bag.application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [self.bag.application registerUserNotificationSettings:settings];
    [self.bag.settings setBool:YES forSetting:MCLSettingBackgroundNotificationsRegistered];
}

- (BOOL)backgroundNotificationsRegistered
{
    return self.bag.application.currentUserNotificationSettings.types != UIUserNotificationTypeNone;
}

- (BOOL)backgroundNotificationsEnabled
{
    return [self.bag.settings integerForSetting:MCLSettingBackgroundNotifications] ?: NO;
}

- (void)sendLocalNotificationForResponse:(MCLResponse *)response
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.userInfo = @{@"type": kNotificationTypeResponse, @"propertyList": response.propertyList};
    notification.alertAction = NSLocalizedString(@"Open", nil);
    notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"Response from %@:\n%@", nil), response.username, response.subject];
    notification.soundName = @"notification.caf";

    [self.bag.application presentLocalNotificationNow:notification];
}

- (void)sendLocalNotificationForPrivateMessage:(MCLPrivateMessage *)privateMessage
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.userInfo = @{@"type": kNotificationTypePrivateMessage, @"propertyList": privateMessage.propertyList};
    notification.alertAction = NSLocalizedString(@"Open", nil);
    notification.alertBody = [NSString stringWithFormat:@"Private Message from %@:\n%@", privateMessage.username, privateMessage.subject];
    notification.soundName = @"privateMessageReceived.caf";

    [self.bag.application presentLocalNotificationNow:notification];
}

- (void)runForNewNotificationsWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    self.completionHandler = completionHandler;
    [self.queue addOperation:[self notificateAboutNewResponsesOperation]];
    if ([self.bag.features isFeatureWithNameEnabled:MCLFeaturePrivateMessages]) {
        [self.queue addOperation:[self notificateAboutNewPrivateMessagesOperation]];
    }
}

- (AsyncBlockOperation *)notificateAboutNewResponsesOperation
{
    return [AsyncBlockOperation blockOperationWithBlock:^(AsyncBlockOperation *op) {
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

            [op complete];
        }];
    }];
}

- (AsyncBlockOperation *)notificateAboutNewPrivateMessagesOperation
{
    return [AsyncBlockOperation blockOperationWithBlock:^(AsyncBlockOperation *op) {
        [self.bag.privateMessagesManager loadConversationsWithCompletionHandler:^(NSArray *conversations) {
            for (MCLPrivateMessageConversation *conversation in conversations) {
                if (conversation.hasUnreadMessages) {
                    for (MCLPrivateMessage *privateMessage in conversation.messages) {
                        if (!privateMessage.isRead ||
                            [self.privateMessageHistory privateMessageWasAlreadyPresented:privateMessage]) {
                            continue;
                        }

                        privateMessage.username = conversation.username;
                        [self sendLocalNotificationForPrivateMessage:privateMessage];
                        [self.privateMessageHistory addPrivateMessage:privateMessage];

                    }
                    [self.privateMessageHistory persist];
                }
            }

            [op complete];
        }];
    }];
}

- (void)handleReceivedNotification:(UILocalNotification *)notification
{
    [self.bag.router dismissModalIfPresentedWithCompletionHandler:^(BOOL dismissed) {
        if ([notification.userInfo[@"type"] isEqualToString:kNotificationTypeResponse]) {
            MCLResponse *response = [MCLResponse responseWithPropertyList:notification.userInfo[@"propertyList"]];
            MCLMessage *message = [MCLMessage messageFromResponse:response];
            [self.bag.router pushToMessage:message];
        } else if ([notification.userInfo[@"type"] isEqualToString:kNotificationTypePrivateMessage]) {
            MCLPrivateMessage *privateMessage = [MCLPrivateMessage privateMessageWithPropertyList:notification.userInfo[@"propertyList"]];
            MCLUser *user = [MCLUser userWithId:@0 username:privateMessage.username];
            MCLPrivateMessageConversation *coversation = [self.bag.privateMessagesManager conversationForUser:user];
            [self.bag.router pushToPrivateMessagesConversation:coversation];
        }
    }];
}

@end
