//
//  MCLComposeMessageViewControllerDelegate.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLMessage;
@class MCLComposeMessageViewController;
@class MCLComposeMessagePreviewViewController;

@protocol MCLComposeMessageViewControllerDelegate <NSObject>

@required
- (void)composeMessageViewController:(MCLComposeMessageViewController *)composeMessageViewController dismissedWithMessage:(MCLMessage *)message;
- (void)composeMessageViewController:(MCLComposeMessagePreviewViewController *)composeMessageViewController sentMessage:(MCLMessage *)message;

@end
