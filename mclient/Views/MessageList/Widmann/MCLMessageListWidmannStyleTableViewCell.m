//
//  MCLMessageListWidmannStyleTableViewCell.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageListWidmannStyleTableViewCell.h"

@import AVFoundation;

#import "UIView+addConstraints.h"
#import "MCLTheme.h"
#import "MCLMessage.h"
#import "MCLLogin.h"
#import "MCLReadSymbolView.h"
#import "MCLMessageToolbar.h"

NSString *const MCLMessageListWidmannStyleTableViewCellIdentifier = @"WidmannStyleMessageCell";

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

    WKWebViewConfiguration *webViewConfig = [[WKWebViewConfiguration alloc] init];
    webViewConfig.suppressesIncrementalRendering = YES;
    [webViewConfig.userContentController addScriptMessageHandler:self name:@"mclient"];

    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webViewConfig];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.opaque = NO;
    webView.scrollView.scrollEnabled = NO;
    webView.scrollView.scrollsToTop = NO;
    for (id subview in webView.subviews) {
        if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
            [subview setBounces:NO];
        }
    }

    MCLMessageToolbar *toolbar = [[MCLMessageToolbar alloc] init];

    [self.contentView addSubview:indentionImageView];
    [self.contentView addSubview:subjectLabel];
    [self.contentView addSubview:usernameLabel];
    [self.contentView addSubview:dateLabel];
    [self.contentView addSubview:readSymbol];
    [self.contentView addSubview:webView];
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

    NSLayoutConstraint *webViewHeightConstraint = [NSLayoutConstraint constraintWithItem:webView
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
                                                         webView,
                                                         toolbar);

    [self.contentView addConstraints:@"H:[indentionImageView(5)]" views:views];
    [self.contentView addConstraints:@"H:[indentionImageView(5)]-5-[subjectLabel]-5-|" views:views];
    [self.contentView addConstraints:@"H:[indentionImageView]-5-[usernameLabel]-5-[dateLabel]-5-[readSymbol(8)]" views:views];
    [self.contentView addConstraints:@"H:|[webView]|" views:views];
    [self.contentView addConstraints:@"H:|[toolbar]|" views:views];

    [self.contentView addConstraints:@"V:|-10-[indentionImageView(40)]" views:views];
    [self.contentView addConstraints:@"V:|-10-[subjectLabel]-7-[usernameLabel]-10@999-[webView]" views:views];
    [self.contentView addConstraints:@"V:[subjectLabel]-7-[dateLabel]" views:views];
    [self.contentView addConstraints:@"V:[subjectLabel]-10-[readSymbol(8)]" views:views];
    [self.contentView addConstraints:@"V:[webView]|" views:views];
    [self.contentView addConstraints:@"V:[toolbar]|" views:views];

    self.indentionImageView = indentionImageView;
    self.indentionConstraint = indentionConstraint;
    self.subjectLabel = subjectLabel;
    self.usernameLabel = usernameLabel;
    self.dateLabel = dateLabel;
    self.readSymbolView = readSymbol;
    self.webView = webView;
    self.webViewHeightConstraint = webViewHeightConstraint;
    self.toolbar = toolbar;
}

- (void)setMessage:(MCLMessage *)message
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.clipsToBounds = YES;

    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.separatorInset = UIEdgeInsetsZero;

    [self indentView:self.indentionConstraint withLevel:message.level];

    self.indentionImageView.image = [self.indentionImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.indentionImageView.tintColor = [self.currentTheme tableViewSeparatorColor];

    if (self.isActive) {
        self.backgroundColor = [self.currentTheme tableViewCellSelectedBackgroundColor];
        self.webView.backgroundColor = [self.currentTheme tableViewCellSelectedBackgroundColor];
        self.webView.scrollView.backgroundColor = [self.currentTheme tableViewCellSelectedBackgroundColor];

        [self.toolbar setHidden:NO];
        [self.webView loadHTMLString:[message messageHtmlWithTopMargin:0 andTheme:self.currentTheme] baseURL:nil];
    }
    else {
        self.backgroundColor = [self.currentTheme tableViewCellBackgroundColor];
        [self.toolbar setHidden:YES];
        self.webViewHeightConstraint.constant = 0;
    }

    self.toolbar.message = message;
    [self.toolbar setBarTintColor:[self.currentTheme tableViewCellSelectedBackgroundColor]];

    self.indentionImageView.hidden = (self.indexPath.row == 0);

    self.subjectLabel.text = message.subject;
    self.subjectLabel.textColor = [self.currentTheme textColor];

    self.usernameLabel.text = message.username;
    if ([message.username isEqualToString:self.toolbar.login.username]) {
        self.usernameLabel.textColor = [self.currentTheme ownUsernameTextColor];
    }
    else if (message.isMod) {
        self.usernameLabel.textColor = [self.currentTheme modTextColor];
    }
    else {
        self.usernameLabel.textColor = [self.currentTheme usernameTextColor];
    }

    self.dateLabel.text = [self.dateFormatter stringFromDate:message.date];
    self.dateLabel.textColor = [self.currentTheme detailTextColor];

    if (self.indexPath.row == 0 || message.isRead) {
        [self markRead];
    }
    else {
        [self markUnread];
    }
}

- (void)setLogin:(MCLLogin *)login
{
    self.toolbar.login = login;
}

- (void)indentView:(NSLayoutConstraint *)indentionConstraint withLevel:(NSNumber *)level
{
    int indention = 15;
    indentionConstraint.constant = 0 + (indention * [level integerValue]);
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
    NSString *heightCode = @"document.getElementById('content').clientHeight";
    [self.webView evaluateJavaScript:heightCode completionHandler:^(NSString *result, NSError *error) {
        if (!error) {
            CGFloat height = (CGFloat)[result doubleValue] + 54;
            completionHandler(height);
        }
    }];
}

@end
