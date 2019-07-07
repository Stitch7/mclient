//
//  MCLMessageTextView.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageTextView.h"

@interface MCLMessageTextView ()

@property (strong, nonatomic) NSArray *menuItems;
@property (strong, nonatomic) NSArray *menuItemsSubmenuFormatText;
@property (assign, nonatomic) BOOL menuItemsSubmenuFormatTextActive;

@end

@implementation MCLMessageTextView

#pragma mark - Initializers

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) return nil;

    [self configure];

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;

    [self configure];

    return self;
}

#pragma mark - Configuration

- (void)configure
{
    [super configure];

    self.changed = NO;
    self.delegate = self;
    self.textContainer.lineFragmentPadding = 0;

    [self configureNotifications];
    [self configureMenuItems];
}

- (void)configureNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMenuItemDismissed:)
                                                 name:UIMenuControllerDidHideMenuNotification
                                               object:nil];
}

- (void)configureMenuItems
{
    self.menuItems = @[[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Spoiler", nil) action:@selector(formatSelectionAsSpoiler:)],
                       [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Link", nil) action:@selector(formatSelectionAsLink:)],
                       [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Image", nil) action:@selector(formatSelectionAsImage:)]];

    self.menuItemsSubmenuFormatText = @[[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"B", nil) action:@selector(formatSelectionBold:)],
                                        [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"I", nil) action:@selector(formatSelectionItalic:)],
                                        [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"U", nil) action:@selector(formatSelectionUnderline:)],
                                        [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"S", nil) action:@selector(formatSelectionStroke:)]];

    self.menuItemsSubmenuFormatTextActive = NO;

    [[UIMenuController sharedMenuController] setMenuItems:self.menuItems];
}

#pragma mark - MenuController

- (void)onMenuItemDismissed:(id)sender
{
    if (self.menuItemsSubmenuFormatTextActive == YES) {
        [[UIMenuController sharedMenuController] setMenuItems:self.menuItems];
        self.menuItemsSubmenuFormatTextActive = NO;
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    BOOL canPerformAction = [super canPerformAction:action withSender:sender];

    if (action == @selector(paste:) ||
        action == NSSelectorFromString(@"_promptForReplace:") ||
        action == NSSelectorFromString(@"_lookup:") ||
        action == NSSelectorFromString(@"_share:") ||
        action == NSSelectorFromString(@"_define:")
    ) {
        canPerformAction = canPerformAction && self.menuItemsSubmenuFormatTextActive == NO;
    }

    if (action == @selector(cut:) ||
        action == @selector(copy:) ||
        action == @selector(_showTextStyleOptions:)
    ) {
        canPerformAction = self.menuItemsSubmenuFormatTextActive == NO && self.selectedRange.length > 0;
    }

    if (action == @selector(formatSelectionAsSpoiler:) ||
        action == @selector(formatSelectionAsLink:) ||
        action == @selector(formatSelectionAsImage:)
    ) {
        canPerformAction = self.selectedRange.length > 0;
    }

    if (action == @selector(formatSelectionBold:) ||
        action == @selector(formatSelectionItalic:) ||
        action == @selector(formatSelectionUnderline:) ||
        action == @selector(formatSelectionStroke:)
    ) {
        canPerformAction = self.menuItemsSubmenuFormatTextActive;
    }

    return canPerformAction;
}

- (void)_showTextStyleOptions:(id)sender
{
    self.menuItemsSubmenuFormatTextActive = YES;
    UIMenuController *sharedMenuController = [UIMenuController sharedMenuController];
    [sharedMenuController setMenuItems:self.menuItemsSubmenuFormatText];

    CGRect targetRect = CGRectNull;
    UITextRange *selectionRange = [self selectedTextRange];
    NSArray *selectionRects = [self selectionRectsForRange:selectionRange];
    for (UITextSelectionRect *selectionRect in selectionRects) {
        targetRect = CGRectUnion(targetRect, selectionRect.rect);
    }

    [sharedMenuController setTargetRect:targetRect inView:self];
    sharedMenuController.menuVisible = YES;
}

- (BOOL)isStringUrl:(NSString *)string
{
    NSURL *url = [NSURL URLWithString:string];
    return (url && ([[url scheme] isEqualToString:@"http"] || [[url scheme] isEqualToString:@"https"]));
}

- (BOOL)isStringImageUrl:(NSString *)string
{
    BOOL isStringImageUrl = NO;

    if ([self isStringUrl:string]) {
        NSString *lowercaseString = [string lowercaseString];
        if ([lowercaseString hasSuffix:@".jpg"] ||
            [lowercaseString hasSuffix:@".gif"] ||
            [lowercaseString hasSuffix:@".png"]
        ) {
            isStringImageUrl = YES;
        }
    }

    return isStringImageUrl;
}

- (void)paste:(id)sender
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSString *pasteboardString = pasteboard.string;
    if (!pasteboardString) {
        return;
    }

    if ([self isStringUrl:pasteboardString]) {
        NSString *format = [self isStringImageUrl:pasteboardString] ? @"[img:%@]" : @"[%@]";
        pasteboardString = [NSString stringWithFormat:format, pasteboardString];
    }

    [self insertText:pasteboardString];
}

- (void)formatSelectionBold:(id)sender
{
    [self formatSelectionWith:@"[b:%@]"];
}

- (void)formatSelectionItalic:(id)sender
{
    [self formatSelectionWith:@"[i:%@]"];
}

- (void)formatSelectionUnderline:(id)sender
{
    [self formatSelectionWith:@"[u:%@]"];
}

- (void)formatSelectionStroke:(id)sender
{
    [self formatSelectionWith:@"[s:%@]"];
}

- (void)formatSelectionAsSpoiler:(id)sender
{
    [self formatSelectionWith:@"[h:%@]"];
}

- (void)formatSelectionAsLink:(id)sender
{
    NSString *selectedText = [self.text substringWithRange:self.selectedRange];
    if ([self isStringUrl:selectedText]) {
        [self formatSelectionWith:@"[%@]"];
    } else {
        [self.errorHandler invalidURLPasted];
    }
}

- (void)formatSelectionAsImage:(id)sender
{
    NSString *selectedText = [self.text substringWithRange:self.selectedRange];
    if ([self isStringImageUrl:selectedText]) {
        [self formatSelectionWith:@"[img:%@]"];
    } else {
        [self.errorHandler invalidImageURLPasted];
    }
}

- (void)formatSelectionWith:(NSString *)formatString
{
    NSRange range = [self selectedRange];
    NSString *selected = [self.text substringWithRange:range];

    NSString *textViewContent = self.text;
    NSString *replacement = [NSString stringWithFormat:formatString, selected];
    NSString *newContent = [textViewContent stringByReplacingCharactersInRange:range withString:replacement];

    self.text = newContent;

    NSRange selectedRange = range;
    selectedRange.location += [formatString length] - 3;
    self.selectedRange = selectedRange;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    self.changed = YES;
    [self showTextViewCaretPosition:textView];
}

- (void)showTextViewCaretPosition:(UITextView *)textView
{
    CGRect caretRect = [textView caretRectForPosition:self.selectedTextRange.end];
    [textView scrollRectToVisible:caretRect animated:NO];
}

#pragma mark - Keyboard notifications

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    CGFloat keyboardHeight = keyboardFrame.size.height;
    if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) &&
        UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)
    ) {
        keyboardHeight = keyboardFrame.size.width;
    }

    UIEdgeInsets contentInset = self.contentInset;
    contentInset.bottom = keyboardHeight;

    UIEdgeInsets scrollIndicatorInsets = self.scrollIndicatorInsets;
    scrollIndicatorInsets.bottom = keyboardHeight;

    [UIView animateWithDuration:animationDuration animations:^{
        self.contentInset = contentInset;
        self.scrollIndicatorInsets = scrollIndicatorInsets;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSTimeInterval animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    UIEdgeInsets contentInset = self.contentInset;
    contentInset.bottom = 0;

    UIEdgeInsets scrollIndicatorInsets = self.scrollIndicatorInsets;
    scrollIndicatorInsets.bottom = 0;

    [UIView animateWithDuration:animationDuration animations:^{
        self.contentInset = contentInset;
        self.scrollIndicatorInsets = scrollIndicatorInsets;
    }];
}

#pragma mark - Public

- (void)formatBold
{
    [self formatSelectionBold:nil];
}

- (void)formatItalic
{
    [self formatSelectionItalic:nil];
}

- (void)formatUnderline
{
    [self formatSelectionUnderline:nil];
}

- (void)formatStroke
{
    [self formatSelectionStroke:nil];
}

- (void)formatSpoiler
{
    [self formatSelectionAsSpoiler:nil];
}

- (void)addLink:(NSURL *)url
{
    [self formatSelectionAsLink:nil];
}

- (void)addImage:(NSURL *)url
{
    NSString *formattedURL = [NSString stringWithFormat:@"[img:%@]", [url absoluteString]];
    self.text = [self.text stringByAppendingString:formattedURL];
}

@end
