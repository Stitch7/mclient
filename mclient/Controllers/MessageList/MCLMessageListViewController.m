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
#import "MCLLogin.h"
#import "MCLUser.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLMessageToolbarController.h"
#import "MCLMessageToolbar.h"
#import "MCLSplitViewController.h"
#import "MCLLoadingViewController.h"


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
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 480, 44)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [self.bag.themeManager.currentTheme textColor];
    label.numberOfLines = 2;
    label.font = [UIFont boldSystemFontOfSize: 15.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];

    NSString *title = self.thread.subject;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:title];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 0.5;
    paragraphStyle.hyphenationFactor = 1.0;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, title.length)];
    label.attributedText = attributedString;

    self.titleLabel = label;

    return label;
}

- (void)loadingViewControllerStartsRefreshing:(MCLLoadingViewController *)loadingViewController
{ }

- (void)loadingViewController:(MCLLoadingViewController *)loadingViewController hasRefreshedWithData:(NSArray *)newData
{
    self.messages = [newData copy];
    NSIndexPath *top = [NSIndexPath indexPathForRow:NSNotFound inSection:0];
    [self.tableView scrollToRowAtIndexPath:top atScrollPosition:UITableViewScrollPositionTop animated:NO];
    [self.tableView reloadData];
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

#pragma mark - Helper

- (void)presentAlertWithError:(NSError *)error
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                   message:[error localizedDescription]
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                                     }];
    [alert addAction:okAction];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    self.titleLabel.textColor = [self.bag.themeManager.currentTheme navigationBarTextColor];
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
    } else {
        alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Thank you for your contribution \"%@\"", nil), message.subject];
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

- (void)loadThread:(MCLThread *)inThread fromBoard:(MCLBoard *)inBoard
{
    mustOverride();
}

@end
