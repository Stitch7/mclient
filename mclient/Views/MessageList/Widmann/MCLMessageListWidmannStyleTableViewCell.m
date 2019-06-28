//
//  MCLMessageListWidmannStyleTableViewCell.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageListWidmannStyleTableViewCell.h"

@import AVFoundation;

#import "UIView+addConstraints.h"
#import "MCLDependencyBag.h"
#import "MCLSettings.h"
#import "MCLThemeManager.h"
#import "MCLTheme.h"
#import "MCLMessage.h"
#import "MCLLoginManager.h"
#import "MCLReadSymbolView.h"
#import "MCLMessageToolbar.h"

NSString *const MCLMessageListWidmannStyleTableViewCellIdentifier = @"WidmannStyleMessageCell";
NSString *const WebviewMessageHandlerName = @"mclient";

@implementation MCLMessageListWidmannStyleTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) return nil;

    [self configure];

    return self;
}

- (UIEdgeInsets)layoutMargins
{
    return UIEdgeInsetsZero;
}

- (void)configure
{
    self.active = NO;
    self.translatesAutoresizingMaskIntoConstraints = NO;

    UIImageView *indentionImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"messageIndention"]];
    indentionImageView.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *subjectLabel = [[UILabel alloc] init];
    subjectLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subjectLabel.numberOfLines = 0;
    subjectLabel.lineBreakMode = NSLineBreakByCharWrapping;
    subjectLabel.font = [UIFont systemFontOfSize:15.0f];

    UILabel *usernameLabel = [[UILabel alloc] init];
    usernameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    usernameLabel.numberOfLines = 1;
    usernameLabel.font = [UIFont boldSystemFontOfSize:13.0f];

    UILabel *dateLabel = [[UILabel alloc] init];
    dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    dateLabel.numberOfLines = 1;
    dateLabel.font = [UIFont systemFontOfSize:12.0f];

    MCLReadSymbolView *readSymbol = [[MCLReadSymbolView alloc] init];
    readSymbol.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *webViewContainerView = [[UIView alloc] init];
    webViewContainerView.translatesAutoresizingMaskIntoConstraints = false;

    MCLMessageToolbar *toolbar = [[MCLMessageToolbar alloc] init];

    [self.contentView addSubview:indentionImageView];
    [self.contentView addSubview:subjectLabel];
    [self.contentView addSubview:usernameLabel];
    [self.contentView addSubview:dateLabel];
    [self.contentView addSubview:readSymbol];
    [self.contentView addSubview:webViewContainerView];
    [self.contentView addSubview:toolbar];

    NSLayoutConstraint *indentionConstraint = [NSLayoutConstraint
                                               constraintWithItem:indentionImageView
                                               attribute:NSLayoutAttributeLeading
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:self.contentView
                                               attribute:NSLayoutAttributeLeading
                                               multiplier:1.0f
                                               constant:5.0f];
    [self.contentView addConstraint:indentionConstraint];

    NSLayoutConstraint *webViewHeightConstraint = [NSLayoutConstraint constraintWithItem:webViewContainerView
                                                                               attribute:NSLayoutAttributeHeight
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:nil
                                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                                              multiplier:1.1f
                                                                                constant:0.0f];
    [self.contentView addConstraint:webViewHeightConstraint];

    NSDictionary *views = NSDictionaryOfVariableBindings(indentionImageView,
                                                         subjectLabel,
                                                         usernameLabel,
                                                         dateLabel,
                                                         readSymbol,
                                                         webViewContainerView,
                                                         toolbar);

    [self.contentView addConstraints:@"H:[indentionImageView(5)]" views:views];
    [self.contentView addConstraints:@"H:[indentionImageView(5)]-5-[subjectLabel]-5-|" views:views];
    [self.contentView addConstraints:@"H:[indentionImageView]-5-[usernameLabel]-5-[dateLabel]-5-[readSymbol(8)]" views:views];
    [self.contentView addConstraints:@"H:|[webViewContainerView]|" views:views];
    [self.contentView addConstraints:@"H:|[toolbar]|" views:views];

    [self.contentView addConstraints:@"V:|-10-[indentionImageView(40)]" views:views];
    [self.contentView addConstraints:@"V:|-10-[subjectLabel]-7-[usernameLabel]-10@999-[webViewContainerView]" views:views];
    [self.contentView addConstraints:@"V:[subjectLabel]-7-[dateLabel]" views:views];
    [self.contentView addConstraints:@"V:[subjectLabel]-10-[readSymbol(8)]" views:views];
    [self.contentView addConstraints:@"V:[webViewContainerView]|" views:views];
    [self.contentView addConstraints:@"V:[toolbar]|" views:views];

    self.indentionImageView = indentionImageView;
    self.indentionConstraint = indentionConstraint;
    self.subjectLabel = subjectLabel;
    self.usernameLabel = usernameLabel;
    self.dateLabel = dateLabel;
    self.readSymbolView = readSymbol;
    self.webViewContainerView = webViewContainerView;
    self.webViewHeightConstraint = webViewHeightConstraint;
    self.toolbar = toolbar;
}

- (void)setMessage:(MCLMessage *)message
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.clipsToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.separatorInset = UIEdgeInsetsZero;

    id <MCLTheme> currentTheme = self.bag.themeManager.currentTheme;

    [self indentView:self.indentionConstraint withLevel:message.level];

    self.indentionImageView.image = [self.indentionImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.indentionImageView.tintColor = [currentTheme tableViewSeparatorColor];

    if (self.isActive) {
        self.backgroundColor = [currentTheme messageBackgroundColor];
        [self initWebviewWithMessage:message];
    } else {
        self.backgroundColor = [currentTheme tableViewCellBackgroundColor];
        [self deinitWebview];
    }

    self.toolbar.hidden = !self.isActive;
    self.toolbar.message = message;
    [self.toolbar setBarTintColor:[currentTheme messageBackgroundColor]];

    self.indentionImageView.hidden = (self.indexPath.row == 0);

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.hyphenationFactor = 1.0f;
    NSDictionary<NSAttributedStringKey, id> *subjectParagraphAttributes = @{ NSParagraphStyleAttributeName: paragraphStyle,
                                                                             NSForegroundColorAttributeName: [currentTheme textColor] };
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:message.subject
                                                                                         attributes:subjectParagraphAttributes];
    self.subjectLabel.attributedText = attributedString;

    self.usernameLabel.text = message.username;
    if ([message.username isEqualToString:self.toolbar.loginManager.username]) {
        self.usernameLabel.textColor = [currentTheme ownUsernameTextColor];
    } else if (message.isMod) {
        self.usernameLabel.textColor = [currentTheme modTextColor];
    } else {
        self.usernameLabel.textColor = [currentTheme usernameTextColor];
    }

    self.dateLabel.text = [self.dateFormatter stringFromDate:message.date];
    self.dateLabel.textColor = [currentTheme detailTextColor];

    if (message.isRead) {
        [self markRead];
    } else {
        [self markUnread];
    }
}

- (void)setNextMessage:(MCLMessage *)nextMessage
{
    self.toolbar.nextMessage = nextMessage;
}

- (void)setLoginManager:(MCLLoginManager *)loginManager
{
    self.toolbar.loginManager = loginManager;
}

- (void)initWebviewWithMessage:(MCLMessage *)message
{
    WKWebViewConfiguration *webViewConfig = [[WKWebViewConfiguration alloc] init];
    webViewConfig.suppressesIncrementalRendering = YES;
    [webViewConfig.userContentController addScriptMessageHandler:self name:WebviewMessageHandlerName];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        webViewConfig.dataDetectorTypes = WKDataDetectorTypeLink;
    }

    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webViewConfig];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.opaque = NO;
    self.webView.backgroundColor = [self.bag.themeManager.currentTheme messageBackgroundColor];
    self.webView.scrollView.backgroundColor = [self.bag.themeManager.currentTheme messageBackgroundColor];
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.scrollView.scrollsToTop = NO;
    for (id subview in self.webView.subviews) {
        if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
            [subview setBounces:NO];
        }
    }

    [self.webViewContainerView addSubview:self.webView];
    [self.webView constrainEdgesTo:self.webViewContainerView];

    [self.webView setNavigationDelegate:self.delegate];

    NSString *messageHtml = [message messageHtmlWithTopMargin:0
                                                        width:self.contentView.bounds.size.width
                                                        theme:self.bag.themeManager.currentTheme
                                                     settings:self.bag.settings];
    [self.webView loadHTMLString:messageHtml baseURL:nil];

    [self.toolbar updateBarButtonsWithMessage:message];
}

- (void)deinitWebview
{
    self.webViewHeightConstraint.constant = 0;

    if (self.webView) {
        [self.webView removeFromSuperview];
        [self.webView.configuration.userContentController removeScriptMessageHandlerForName:WebviewMessageHandlerName];
        self.webView = nil;
    }
}

- (void)indentView:(NSLayoutConstraint *)indentionConstraint withLevel:(NSNumber *)level
{
    int indention = 15;
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat maxWidth = screenWidth - screenWidth * 0.2;
    CGFloat newVal = 0 + (indention * [level integerValue]);

    indentionConstraint.constant = newVal > maxWidth ? maxWidth : newVal;
}

- (void)markRead
{
    self.readSymbolView.hidden = YES;
    self.subjectLabel.font = [UIFont systemFontOfSize:15.0f];
}

- (void)markUnread
{
    self.readSymbolView.hidden = NO;
    self.subjectLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightSemibold];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSDictionary *sentData = (NSDictionary *)message.body;
    if ([sentData[@"message"] isEqualToString:@"content-changed"]) {
        [self.delegate contentChanged];
    }
}

#pragma mark - Actions

- (void)contentHeightWithCompletion:(void (^)(CGFloat height))completionHandler
{
    CGFloat offset = 54;

    NSString *heightCode = @"document.getElementById('content').clientHeight";
    [self.webView evaluateJavaScript:heightCode completionHandler:^(NSString *result, NSError *error) {
        if (!error) {
            CGFloat height = (CGFloat)[result doubleValue] + offset;
            completionHandler(height);

            // Sometimes height gets evaluated wrong, let's calculate it again after 0.5 secs
            // and reinvoke completion handler if new result differs
            double delayInSeconds = 0.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                [self.webView evaluateJavaScript:heightCode completionHandler:^(NSString *result2, NSError *error2) {
                    if (!error2) {
                        CGFloat newHeight = (CGFloat)[result2 doubleValue] + offset;
                        if (newHeight != height) {
                            completionHandler(newHeight);
                        }
                    }
                }];
            });
        }
    }];
}

@end
