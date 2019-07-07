//
//  MCLMessageTextViewToolbarDelegate.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLMessageTextViewToolbar;

@protocol MCLMessageTextViewToolbarDelegate <NSObject>

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar boldButtonPressed:(UIBarButtonItem *)sender;
- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar italicButtonPressed:(UIBarButtonItem *)sender;
- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar underlineButtonPressed:(UIBarButtonItem *)sender;
- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar strikestroughButtonPressed:(UIBarButtonItem *)sender;
- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar spoilerButtonPressed:(UIBarButtonItem *)sender;
- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar cameraButtonPressed:(UIBarButtonItem *)sender;
- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar quoteButtonPressed:(UIBarButtonItem *)sender;

@end
