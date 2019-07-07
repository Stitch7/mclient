//
//  MCLKeyboardShortcutManager.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLKeyboardShortcutManager.h"

#import "MCLDependencyBag.h"
#import "MCLRouter+mainNavigation.h"
#import "MCLThreadsKeyboardShortcutsDelegate.h"
#import "MCLMessageKeyboardShortcutsDelegate.h"
#import "MCLBoard.h"


NSString * const MCLKeyboardShortcutDismissDialog = @"dismissDialog";
NSString * const MCLKeyboardShortcutComposeThread = @"composeThread";
NSString * const MCLKeyboardShortcutSelectPreviousThread = @"selectPreviousThread";
NSString * const MCLKeyboardShortcutSelectNextThread = @"selectNextThread";
NSString * const MCLKeyboardShortcutSelectPreviousMessage = @"selectPreviousMessage";
NSString * const MCLKeyboardShortcutSelectNextMessage = @"selectNextMessage";
NSString * const MCLKeyboardShortcutOpenProfile = @"openProfile";
NSString * const MCLKeyboardShortcutCopyLink = @"copyLink";
NSString * const MCLKeyboardShortcutComposeEdit = @"composeEdit";
NSString * const MCLKeyboardShortcutComposeReply = @"composeReply";

@interface MCLKeyboardShortcutManager ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) NSArray<UIKeyCommand *>* boardKeyCommands;
@property (strong, nonatomic) NSDictionary<NSString *, UIKeyCommand *>* allKeyCommands;

@end

@implementation MCLKeyboardShortcutManager

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;

    return self;
}

- (void)setBoards:(NSArray<MCLBoard *> *)boards
{
    _boards = boards;
    NSMutableArray<UIKeyCommand *>* boardKeyCommands = [[NSMutableArray alloc] init];
    int i = 0;
    for (MCLBoard *board in _boards) {
        NSString *discoverabilityTitle = [NSLocalizedString(@"keyboardShortcutGoTo", nil) stringByAppendingString:board.name];
        [boardKeyCommands addObject:[UIKeyCommand keyCommandWithInput:[[NSNumber numberWithInteger:++i] stringValue]
                                                        modifierFlags:kNilOptions
                                                               action:@selector(routeToBoard:)
                                                 discoverabilityTitle:discoverabilityTitle]];
    }

    self.boardKeyCommands = boardKeyCommands;
}

#pragma mark - UIResponder overrides

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (NSDictionary<NSString *, UIKeyCommand *>*)allKeyCommands
{
    if (!_allKeyCommands) {
        _allKeyCommands = @{
            MCLKeyboardShortcutDismissDialog:
                [UIKeyCommand keyCommandWithInput:@"w"
                                    modifierFlags:UIKeyModifierCommand
                                           action:@selector(dismissDialog:)
                             discoverabilityTitle:NSLocalizedString(@"keyboardShortcutDismissDialog", nil)],

            MCLKeyboardShortcutComposeThread:
                [UIKeyCommand keyCommandWithInput:@"n"
                                    modifierFlags:UIKeyModifierCommand
                                           action:@selector(composeThread:)
                             discoverabilityTitle:NSLocalizedString(@"keyboardShortcutComposeThread", nil)],

            MCLKeyboardShortcutSelectPreviousThread:
                [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow
                                    modifierFlags:kNilOptions
                                           action:@selector(selectPreviousThread:)
                             discoverabilityTitle:NSLocalizedString(@"keyboardShortcutSelectPreviousThread", nil)],
            MCLKeyboardShortcutSelectNextThread:
                [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow
                                    modifierFlags:kNilOptions
                                           action:@selector(selectNextThread:)
                             discoverabilityTitle:NSLocalizedString(@"keyboardShortcutSelectNextThread", nil)],

            MCLKeyboardShortcutSelectPreviousMessage:
                [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow
                                    modifierFlags:kNilOptions
                                           action:@selector(selectPreviousMessage:)
                             discoverabilityTitle:NSLocalizedString(@"keyboardShortcutSelectPreviousMessage", nil)],

            MCLKeyboardShortcutSelectNextMessage:
                [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow
                                    modifierFlags:kNilOptions
                                           action:@selector(selectNextMessage:)
                             discoverabilityTitle:NSLocalizedString(@"keyboardShortcutSelectNextMessage", nil)],

            MCLKeyboardShortcutOpenProfile:
                [UIKeyCommand keyCommandWithInput:@"u"
                                    modifierFlags:UIKeyModifierCommand
                                           action:@selector(openProfile:)
                             discoverabilityTitle:NSLocalizedString(@"keyboardShortcutOpenProfile", nil)],

            MCLKeyboardShortcutCopyLink:
                [UIKeyCommand keyCommandWithInput:@"c"
                                    modifierFlags:UIKeyModifierCommand
                                           action:@selector(copyLink:)
                             discoverabilityTitle:NSLocalizedString(@"keyboardShortcutCopyLink", nil)],

            MCLKeyboardShortcutComposeEdit:
                [UIKeyCommand keyCommandWithInput:@"e"
                                    modifierFlags:UIKeyModifierCommand
                                           action:@selector(composeEdit:)
                             discoverabilityTitle:NSLocalizedString(@"keyboardShortcutComposeEdit", nil)],

            MCLKeyboardShortcutComposeReply:
                [UIKeyCommand keyCommandWithInput:@"r"
                                    modifierFlags:UIKeyModifierCommand
                                           action:@selector(composeReply:)
                             discoverabilityTitle:NSLocalizedString(@"keyboardShortcutComposeReply", nil)],
         };
    }

    return _allKeyCommands;
}

- (NSArray<UIKeyCommand *>*)keyCommands
{
    NSMutableArray<UIKeyCommand *>* keyCommands = [[NSMutableArray alloc] init];
    
    if ([self.bag.router modalIsPresented]) {
        [keyCommands addObject:self.allKeyCommands[MCLKeyboardShortcutDismissDialog]];
    } else {
        keyCommands = [NSMutableArray arrayWithArray:self.boardKeyCommands];

        if (self.threadsKeyboardShortcutsDelegate) {
            [keyCommands addObject:self.allKeyCommands[MCLKeyboardShortcutComposeThread]];
            [keyCommands addObject:self.allKeyCommands[MCLKeyboardShortcutSelectPreviousThread]];
            [keyCommands addObject:self.allKeyCommands[MCLKeyboardShortcutSelectNextThread]];
        }

        if ([self.messageKeyboardShortcutsDelegate aMessageIsSelected]) {
            [keyCommands addObject:self.allKeyCommands[MCLKeyboardShortcutSelectPreviousMessage]];
            [keyCommands addObject:self.allKeyCommands[MCLKeyboardShortcutSelectNextMessage]];
            [keyCommands addObject:self.allKeyCommands[MCLKeyboardShortcutOpenProfile]];
            [keyCommands addObject:self.allKeyCommands[MCLKeyboardShortcutCopyLink]];

            if ([self.messageKeyboardShortcutsDelegate selectedMessageIsEditable]) {
                [keyCommands addObject:self.allKeyCommands[MCLKeyboardShortcutComposeEdit]];
            }
            if ([self.messageKeyboardShortcutsDelegate selectedMessageIsOpenForReply]) {
                [keyCommands addObject:self.allKeyCommands[MCLKeyboardShortcutComposeReply]];
            }
        }
    }

    return keyCommands;
}

/** TODO
 * - if modalIsPresented doen't work on profile
 * - frame style read selection
 * - test i18n
 **/

#pragma mark - UIResponder overrides

- (void)routeToBoard:(UIKeyCommand *)sender
{
    NSNumber *boardId;
    NSString *boardName = [sender.discoverabilityTitle stringByReplacingOccurrencesOfString:NSLocalizedString(@"keyboardShortcutGoTo", nil)
                                                                                 withString:@""];
    for (MCLBoard *board in self.boards) {
        if ([board.name isEqualToString:boardName]) {
            boardId = board.boardId;
            break;
        }
    }

    if (boardId) {
        MCLBoard *board = [MCLBoard boardWithId:boardId name:boardName];
        [self.bag.router pushToThreadListFromBoard:board];
    }
}

#pragma mark - Actions

- (void)dismissDialog:(UIKeyCommand *)sender
{
    [self.bag.router dismissModalIfPresentedWithCompletionHandler:nil];
}

- (void)composeThread:(UIKeyCommand *)sender
{
    [self.threadsKeyboardShortcutsDelegate keyboardShortcutComposeThreadPressed];
}

- (void)selectPreviousThread:(UIKeyCommand *)sender
{
    [self.threadsKeyboardShortcutsDelegate keyboardShortcutSelectPreviousThreadPressed];
}

- (void)selectNextThread:(UIKeyCommand *)sender
{
    [self.threadsKeyboardShortcutsDelegate keyboardShortcutSelectNextThreadPressed];
}

- (void)selectPreviousMessage:(UIKeyCommand *)sender
{
    [self.messageKeyboardShortcutsDelegate keyboardShortcutSelectPreviousMessagePressed];
}

- (void)selectNextMessage:(UIKeyCommand *)sender
{
    [self.messageKeyboardShortcutsDelegate keyboardShortcutSelectNextMessagePressed];
}

- (void)openProfile:(UIKeyCommand *)sender
{
    [self.messageKeyboardShortcutsDelegate keyboardShortcutOpenProfilePressed];
}

- (void)copyLink:(UIKeyCommand *)sender
{
    [self.messageKeyboardShortcutsDelegate keyboardShortcutCopyLinkPressed];
}

- (void)composeReply:(UIKeyCommand *)sender
{
    [self.messageKeyboardShortcutsDelegate keyboardShortcutComposeReplyPressed];
}

- (void)composeEdit:(UIKeyCommand *)sender
{
    [self.messageKeyboardShortcutsDelegate keyboardShortcutComposeEditPressed];
}

@end
