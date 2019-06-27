//
//  MCLKeyboardShortcutManager.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;
@protocol MCLThreadsKeyboardShortcutsDelegate;
@protocol MCLMessageKeyboardShortcutsDelegate;
@class MCLBoard;

@interface MCLKeyboardShortcutManager : UIResponder

@property (weak) id<MCLThreadsKeyboardShortcutsDelegate> threadsKeyboardShortcutsDelegate;
@property (weak) id<MCLMessageKeyboardShortcutsDelegate> messageKeyboardShortcutsDelegate;
@property (strong, nonatomic) NSArray<MCLBoard *> *boards;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;

@end
