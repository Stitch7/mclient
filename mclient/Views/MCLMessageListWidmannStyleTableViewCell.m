//
//  MCLMessageListWidmannStyleTableViewCell.m
//  mclient
//
//  Created by Christopher Reitz on 30/12/2016.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

#import "MCLMessageListWidmannStyleTableViewCell.h"

#import <AVFoundation/AVFoundation.h>
#import "constants.h"
#import "UIView+addConstraints.h"
#import "KeychainItemWrapper.h"
#import "MCLMServiceConnector.h"
#import "MCLReadSymbolView.h"

@implementation MCLMessageListWidmannStyleTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self configure];
    }
    return self;
}

- (UIEdgeInsets)layoutMargins
{
    return UIEdgeInsetsZero;
}

- (void)configure
{
    self.translatesAutoresizingMaskIntoConstraints = NO;

    UIImageView *indentionImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"messageIndention.png"]];
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

    UIToolbar *toolbar = [[UIToolbar alloc] init];
    toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                            target:nil
                                                                            action:nil];

    UIBarButtonItem *buttonProfile = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"profileButton.png"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(openProfileAction:)];

    UIBarButtonItem *buttonCopyLink = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"copyLinkButton.png"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(copyLinkAction:)];

    UIBarButtonItem *buttonSpeak = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"speakButton.png"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(speakAction:)];

    UIBarButtonItem *buttonNotification = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"notificationButton.png"]
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(notificationAction:)];

    UIBarButtonItem *buttonEdit = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"editButton.png"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(editAction:)];

    UIBarButtonItem *buttonReply = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply
                                                                                 target:self
                                                                                 action:@selector(replyAction:)];

    [toolbar setItems:@[buttonProfile,
                        spacer,
                        buttonCopyLink,
                        spacer,
                        buttonSpeak,
                        spacer,
                        buttonNotification,
                        spacer,
                        buttonEdit,
                        spacer,
                        buttonReply]];

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

    [self.contentView addConstraints:@"V:|-15-[indentionImageView(40)]" views:views];
    [self.contentView addConstraints:@"V:|-10-[subjectLabel]-5-[usernameLabel]-10@999-[webView]" views:views];
    [self.contentView addConstraints:@"V:[subjectLabel]-6-[dateLabel]" views:views];
    [self.contentView addConstraints:@"V:[subjectLabel]-9-[readSymbol(8)]" views:views];
    [self.contentView addConstraints:@"V:[webView]|" views:views];
    [self.contentView addConstraints:@"V:[toolbar]|" views:views];

    self.messageIndentionImageView = indentionImageView;
    self.messageIndentionConstraint = indentionConstraint;
    self.messageSubjectLabel = subjectLabel;
    self.messageUsernameLabel = usernameLabel;
    self.messageDateLabel = dateLabel;
    self.readSymbolView = readSymbol;
    self.messageTextWebView = webView;
    self.messageTextWebViewHeightConstraint = webViewHeightConstraint;
    self.messageToolbar = toolbar;
    self.messageProfileButton = buttonProfile;
    self.messageSpeakButton = buttonSpeak;
    self.messageNotificationButton = buttonNotification;
    self.messageEditButton = buttonEdit;
    self.messageReplyButton = buttonReply;
}

- (void)markRead
{
    self.readSymbolView.hidden = YES;
    self.messageSubjectLabel.font = [UIFont systemFontOfSize:15.0f];
}

- (void)markUnread
{
    self.readSymbolView.hidden = NO;
    self.messageSubjectLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightSemibold];
}

- (void)enableNotificationButton:(BOOL)enable
{
    self.messageNotification = enable;

    if (enable) {
        self.messageNotificationButton.image = [UIImage imageNamed:@"notificationButtonEnabled.png"];
    } else {
        self.messageNotificationButton.image = [UIImage imageNamed:@"notificationButtonDisabled.png"];
    }
}

#pragma mark - AVSpeechSynthesizerDelegate

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
    self.messageSpeakButton.image = [UIImage imageNamed:@"stopButton.png"];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    self.messageSpeakButton.image = [UIImage imageNamed:@"speakButton.png"];
}

#pragma mark - Actions

- (void)openProfileAction:(UIBarButtonItem *)sender
{
    [self.delegate openProfileButtonPressed];
}


- (void)copyLinkAction:(UIBarButtonItem *)sender
{
    NSString *link = [NSString stringWithFormat:@"%@?mode=message&brdid=%@&msgid=%@", kManiacForumURL, self.boardId, self.messageId];

    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = link;

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Copied link", nil)
                                                    message:NSLocalizedString(@"URL for this message was copied to clipboard", nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)speakAction:(UIBarButtonItem *)sender
{
    if (self.speechSynthesizer == nil) {
        self.speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
        self.speechSynthesizer.delegate = self;
    }

    if (self.speechSynthesizer.speaking) {
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
        self.messageSpeakButton.image = [UIImage imageNamed:@"speakButton.png"];
    } else {
        // Backup of UIWebView content because it's get manipulated by our operation below
        NSString *js1 = @"document.getElementsByTagName(\"html\")[0].innerHTML;";
        [self.messageTextWebView evaluateJavaScript:js1 completionHandler:^(NSString *result, NSError *error) {
            if (error != nil) { return; }

            NSString *webviewTextBackup = result;

            // Remove quoted text (font tags)
            NSString *js2 = @"var fontTags = document.getElementsByTagName(\"font\");"
                            " for (var i=0; i < fontTags.length; x++) { fontTags[i].remove() };";
            [self.messageTextWebView evaluateJavaScript:js2 completionHandler:nil];

            NSString *js3 = @"document.getElementsByTagName(\"body\")[0].textContent;";
            [self.messageTextWebView evaluateJavaScript:js3 completionHandler:^(NSString *result, NSError *error) {
                if (error != nil) { return; }

                NSString *text = result;
                text = [[self.messageSubjectLabel.text  stringByAppendingString:@"..."] stringByAppendingString:text];
                text = [[NSString stringWithFormat:@"Von %@...", self.messageUsernameLabel.text] stringByAppendingString:text];

                // Restoring backuped original content
                [self.messageTextWebView loadHTMLString:webviewTextBackup baseURL:nil];

                // Speak text
                AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
                [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"de-DE"]];

                [self.speechSynthesizer speakUtterance:utterance];
            }];
        }];
    }
}

- (void)notificationAction:(UIBarButtonItem *)sender
{
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    NSString *username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    NSData *passwordData = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        [[MCLMServiceConnector sharedConnector] notificationForMessageId:self.messageId
                                                                 boardId:self.boardId
                                                                username:username
                                                                password:password
                                                                   error:&mServiceError];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

            NSString *alertTitle, *alertMessage;
            if (mServiceError) {
                alertTitle = NSLocalizedString(@"Error", nil);
                alertMessage = [mServiceError localizedDescription];
            } else if (self.messageNotification) {
                [self enableNotificationButton:NO];
                alertTitle = NSLocalizedString(@"Notification disabled", nil);
                alertMessage = NSLocalizedString(@"You will no longer receive Emails if anyone replies to this message", nil);
            } else {
                [self enableNotificationButton:YES];
                alertTitle = NSLocalizedString(@"Notification enabled", nil);
                alertMessage = NSLocalizedString(@"You will receive an Email if anyone replies to this message", nil);
            }

            [[[UIAlertView alloc] initWithTitle:alertTitle
                                        message:alertMessage
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
        });
    });
}

- (void)editAction:(UIBarButtonItem *)sender
{
    [self.delegate editButtonPressed];
}

- (void)replyAction:(UIBarButtonItem *)sender
{
    [self.delegate replyButtonPressed];
}

@end
