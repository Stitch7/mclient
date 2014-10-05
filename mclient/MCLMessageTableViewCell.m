//
//  MCLMessageTableViewCell.m
//  mclient
//
//  Created by Christopher Reitz on 26.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "constants.h"
#import "MCLMessageTableViewCell.h"
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
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                    message:@"Copied link to this message to clipboard"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
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
        [utterance setRate:AVSpeechUtteranceDefaultSpeechRate];
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
    
    NSError *mServiceError;
    BOOL success = [[MCLMServiceConnector sharedConnector] notificationForMessageId:self.messageId boardId:self.boardId username:username password:password error:&mServiceError];

    NSString *alertTitle, *alertMessage;

    if ( ! success) {
        alertTitle = [mServiceError localizedDescription];
        alertMessage = [mServiceError localizedFailureReason];
    } else if (self.messageNotification) {
        [self enableNotificationButton:NO];
        alertTitle = @"Message notification disabled";
        alertMessage = @"You will no longer receive Emails if anyone replies to this post.";
    } else {
        [self enableNotificationButton:YES];
        alertTitle = @"Message notification enabled";
        alertMessage = @"You will receive an Email if anyone answers to this post.";
    }

    [[[UIAlertView alloc] initWithTitle:alertTitle
                                message:alertMessage
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

@end
