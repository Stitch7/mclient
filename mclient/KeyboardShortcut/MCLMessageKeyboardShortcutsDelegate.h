//
//  MCLMessageKeyboardShortcutsDelegate.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLMessageKeyboardShortcutsDelegate <NSObject>

- (BOOL)aMessageIsSelected;
- (void)keyboardShortcutSelectPreviousMessagePressed;
- (void)keyboardShortcutSelectNextMessagePressed;
- (void)keyboardShortcutOpenProfilePressed;
- (void)keyboardShortcutCopyLinkPressed;
- (BOOL)selectedMessageIsEditable;
- (void)keyboardShortcutComposeEditPressed;
- (BOOL)selectedMessageIsOpenForReply;
- (void)keyboardShortcutComposeReplyPressed;

@end
