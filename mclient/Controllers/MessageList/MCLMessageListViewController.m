//
//  MCLMessageListViewController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@import WebKit;

#import "MCLMessageListViewController.h"

#import "MCLDependencyBag.h"
#import "MCLSettings.h"
#import "MCLRouter+mainNavigation.h"
#import "MCLRouter+openURL.h"
#import "MCLThemeManager.h"
#import "MCLSoundEffectPlayer.h"
#import "MCLLogin.h"
#import "MCLUser.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLMessageToolbarController.h"
#import "MCLMessageToolbar.h"
#import "MCLSplitViewController.h"
#import "MCLLoadingViewController.h"
#import "MCLMultilineTitleLabel.h"


@implementation MCLMessageListViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;
    [self initialize];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initialize
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];
}

#pragma mark - Lazy Properties

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.doesRelativeDateFormatting = YES;
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }

    return _dateFormatter;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.messageToolbarController = [[MCLMessageToolbarController alloc] initWithBag:self.bag messageListViewController:self];

    [self themeChanged:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setToolbarHidden:YES animated:NO];
}

#pragma mark - MCLLoadingContentViewControllerDelegate

- (NSString *)loadingViewControllerRequestsTitleString:(MCLLoadingViewController *)loadingViewController
{
    return self.thread.subject;
}

- (UILabel *)loadingViewControllerRequestsTitleLabel:(MCLLoadingViewController *)loadingViewController
{
    return [self titleLabel];
}

- (UILabel *)titleLabel
{
    return [[MCLMultilineTitleLabel alloc] initWithThemeManager:self.bag.themeManager andTitle:self.thread.subject];
}

- (void)loadingViewController:(MCLLoadingViewController *)loadingViewController hasRefreshedWithData:(NSArray *)newData forKey:(NSNumber *)key
{
    self.messages = [newData copy];

    [UIView animateWithDuration:0 animations:^{
        [self.tableView reloadData];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0 animations:^{
            NSIndexPath *top = [NSIndexPath indexPathForRow:NSNotFound inSection:0];
            [self.tableView scrollToRowAtIndexPath:top atScrollPosition:UITableViewScrollPositionTop animated:NO];
        } completion:^(BOOL finished) {
            [self selectInitialMessage];
        }];
    }];
}

- (void)backButtonPressed:(UIBarButtonItem *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSURL *destinationURL = navigationAction.request.URL;
        [self.bag.router pushToURL:destinationURL];
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
}

# pragma mark - 

- (void)selectInitialMessage
{
    if (!(self.thread && self.messages)) {
        return;
    }

    NSNumber *lastMessageId = self.thread.lastMessageId;
    BOOL firstMessageIsRead = self.thread.isRead;
    BOOL jumpToLatestPost = [self.bag.settings isSettingActivated:MCLSettingJumpToLatestPost];
    BOOL lastMessageExists = lastMessageId > 0;
    BOOL lastMessageIsNotRead = !self.thread.lastMessageIsRead;

    if (self.jumpToMessageId) {
        [self.messages enumerateObjectsUsingBlock:^(MCLMessage *message, NSUInteger key, BOOL *stop) {
            if (self.jumpToMessageId == message.messageId) {
                NSIndexPath *jumpToMessageIndexPath = [NSIndexPath indexPathForRow:key inSection:0];
                [self.tableView scrollToRowAtIndexPath:jumpToMessageIndexPath
                                      atScrollPosition:UITableViewScrollPositionTop
                                              animated:YES];
                [self tableView:self.tableView didSelectRowAtIndexPath:jumpToMessageIndexPath];
                *stop = YES;
            }
        }];

        return;
    }

    if (firstMessageIsRead && jumpToLatestPost && lastMessageExists && lastMessageIsNotRead) {
        [self.messages enumerateObjectsUsingBlock:^(MCLMessage *message, NSUInteger key, BOOL *stop) {
            if (self.thread.lastMessageId == message.messageId) {
                NSIndexPath *latestMessageIndexPath = [NSIndexPath indexPathForRow:key inSection:0];
                [self.tableView scrollToRowAtIndexPath:latestMessageIndexPath
                                      atScrollPosition:UITableViewScrollPositionTop
                                              animated:YES];
                self.thread.lastMessageRead = YES;
                [self tableView:self.tableView didSelectRowAtIndexPath:latestMessageIndexPath];
                *stop = YES;
            }
        }];

        return;
    }

    // Select first message
    NSIndexPath *indexPathOfFirstMessage = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:indexPathOfFirstMessage
                                animated:NO
                          scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPathOfFirstMessage];
}

#pragma mark - MCLComposeMessageViewControllerDelegate

- (void)message:(MCLMessage *)message sentWithType:(NSUInteger)type
{
    [self.loadingViewController refresh];

    NSString *alertMessage;
    if (type == kMCLComposeTypeEdit) {
        alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Your message \"%@\" was changed", nil), message.subject];
        [self.bag.soundEffectPlayer playEditPostingSound];
    } else {
        alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Thank you for your contribution \"%@\"", nil), message.subject];
        [self.bag.soundEffectPlayer playCreatePostingSound];
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirmation", nil)
                                                                   message:alertMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];;

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Abstract methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    mustOverride();
}

@end
