//
//  MCLMessageTableViewCell.m
//  mclient
//
//  Created by Christopher Reitz on 26.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLMessageTableViewCell.h"

#import <AVFoundation/AVFoundation.h>
#import "constants.h"
#import "KeychainItemWrapper.h"
#import "MCLMServiceConnector.h"
#import "MCLReadSymbolView.h"

@implementation MCLMessageTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)markRead
{
    self.readSymbolView.hidden = YES;
}

- (void)markUnread
{
    self.readSymbolView.hidden = NO;
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

- (IBAction)copyLinkAction:(UIBarButtonItem *)sender
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

- (IBAction)speakAction:(UIBarButtonItem *)sender
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
        NSString *webviewTextBackup = [self.messageTextWebView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName(\"html\")[0].innerHTML;"];

        // Remove quoted text (font tags)
        [self.messageTextWebView stringByEvaluatingJavaScriptFromString:@"var fontTags = document.getElementsByTagName(\"font\"); for (var i=0; i < fontTags.length; x++) { fontTags[i].remove() };"];
        NSString *text = [self.messageTextWebView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName(\"body\")[0].textContent;"];
        text = [[self.messageSubjectLabel.text  stringByAppendingString:@"..."] stringByAppendingString:text];
        text = [[NSString stringWithFormat:@"Von %@...", self.messageUsernameLabel.text] stringByAppendingString:text];

        // Restoring backuped original content
        [self.messageTextWebView loadHTMLString:webviewTextBackup baseURL:nil];

        // Speak text
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
        [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"de-DE"]];

        [self.speechSynthesizer speakUtterance:utterance];
    }
}

- (IBAction)notificationAction:(UIBarButtonItem *)sender
{
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    NSString *username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    NSData *passwordData = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        [[MCLMServiceConnector sharedConnector] notificationForMessageId:self.messageId boardId:self.boardId username:username password:password error:&mServiceError];
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

@end
