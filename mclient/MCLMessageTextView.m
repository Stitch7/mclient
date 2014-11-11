//
//  MCLMessageTextView.m
//  mclient
//
//  Created by Christopher Reitz on 24.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLMessageTextView.h"

@interface MCLMessageTextView ()

@property (strong, nonatomic) NSArray *menuItems;
@property (strong, nonatomic) NSArray *menuItemsSubmenuFormatText;
@property (assign, nonatomic) BOOL menuItemsSubmenuFormatTextActive;

@end


@implementation MCLMessageTextView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self configure];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self configure];
    }

    return self;
}


- (void)configure
{
    self.delegate = self;

    self.textContainer.lineFragmentPadding = 0;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    self.menuItems = @[[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Spoiler", nil) action:@selector(formatSpoiler:)],
                       [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Link", nil) action:@selector(formatLink:)],
                       [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Image", nil) action:@selector(formatImage:)]];

    self.menuItemsSubmenuFormatText = @[[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"B", nil) action:@selector(formatBold:)],
                                        [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"I", nil) action:@selector(formatItalic:)],
                                        [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"U", nil) action:@selector(formatUnderline:)],
                                        [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"S", nil) action:@selector(formatStroke:)]];

    self.menuItemsSubmenuFormatTextActive = NO;

    [[UIMenuController sharedMenuController] setMenuItems:self.menuItems];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMenuItemDismissed:) name:UIMenuControllerDidHideMenuNotification object:nil];
}

#pragma mark - MenuController

- (void)onMenuItemDismissed:(id)sender
{
    if (self.menuItemsSubmenuFormatTextActive == YES){
        [[UIMenuController sharedMenuController] setMenuItems:self.menuItems];
        self.menuItemsSubmenuFormatTextActive = NO;
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    BOOL canPerformAction = [super canPerformAction:action withSender:sender];

//// Surpress undeclared selector warnings
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wundeclared-selector"
//    if (action == @selector(_promptForReplace:) ||
//        action == @selector(_define:)
//    ) {
//        canPerformAction = NO;
//    }
//#pragma clang diagnostic pop

    if (action == @selector(paste:)) {
        canPerformAction = [UIPasteboard generalPasteboard].string.length > 0 && self.menuItemsSubmenuFormatTextActive == NO;
    }

    if (action == @selector(cut:) ||
        action == @selector(copy:) ||
        action == @selector(_showTextStyleOptions:)
    ) {
        canPerformAction = self.menuItemsSubmenuFormatTextActive == NO && self.selectedRange.length > 0;
    }

    if (action == @selector(formatSpoiler:) ||
        action == @selector(formatLink:) ||
        action == @selector(formatImage:)
    ) {
        canPerformAction = self.selectedRange.length > 0;
    }

    if (action == @selector(formatBold:) ||
        action == @selector(formatItalic:) ||
        action == @selector(formatUnderline:) ||
        action == @selector(formatStroke:)
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

    if ([self isStringUrl:pasteboardString]) {
        NSString *format = @"[%@]";
        if ([self isStringImageUrl:pasteboardString]) {
            format = @"[img:%@]";
        }

        pasteboard.string = [NSString stringWithFormat:format, pasteboardString];
    }

    [super paste:sender];

    pasteboard.string = pasteboardString;
}

- (void)formatBold:(id)sender
{
    [self formatSelectionWith:@"[b:%@]"];
}

- (void)formatItalic:(id)sender
{
    [self formatSelectionWith:@"[i:%@]"];
}

- (void)formatUnderline:(id)sender
{
    [self formatSelectionWith:@"[u:%@]"];
}

- (void)formatStroke:(id)sender
{
    [self formatSelectionWith:@"[s:%@]"];
}

- (void)formatSpoiler:(id)sender
{
    [self formatSelectionWith:@"[h:%@]"];
}

- (void)formatLink:(id)sender
{
    NSString *selectedText = [self.text substringWithRange:self.selectedRange];
    if ([self isStringUrl:selectedText]) {
        [self formatSelectionWith:@"[%@]"];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                        message:NSLocalizedString(@"Selected text is not a valid URL", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)formatImage:(id)sender
{
    NSString *selectedText = [self.text substringWithRange:self.selectedRange];
    if ([self isStringImageUrl:selectedText]) {
        [self formatSelectionWith:@"[img:%@]"];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                        message:NSLocalizedString(@"Selected text is not a valid image URL", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
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
}


#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    [self showTextViewCaretPosition:textView];
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
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

@end
