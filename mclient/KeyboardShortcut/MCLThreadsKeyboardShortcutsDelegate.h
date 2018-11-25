//
//  MCLThreadsKeyboardShortcutsDelegate.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLThreadsKeyboardShortcutsDelegate <NSObject>

- (void)keyboardShortcutComposeThreadPressed;
- (void)keyboardShortcutSelectPreviousThreadPressed;
- (void)keyboardShortcutSelectNextThreadPressed;

@end
