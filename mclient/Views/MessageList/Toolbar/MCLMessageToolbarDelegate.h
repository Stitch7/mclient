//
//  MCLMessageToolbarDelegate.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLMessageToolbar;
@class MCLUser;
@class MCLMessage;

@protocol MCLMessageToolbarDelegate <NSObject>

- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToOpenProfileFromUser:(MCLUser *)user;
- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToCopyMessageLinkToClipboard:(MCLMessage *)message;
- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToSpeakMessage:(MCLMessage *)message;
- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToToggleNotificationButton:(UIBarButtonItem *)notificationButton forMessage:(MCLMessage *)message withCompletionHandler:(void (^)(void))completionHandler;
- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToEditMessage:(MCLMessage *)message;
- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToReplyToMessage:(MCLMessage *)message;

@end
