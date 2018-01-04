//
//  MCLMessageToolbarController.m
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageToolbarController.h"

@import WebKit;

#import "MCLDependencyBag.h"
#import "MCLNotificationStatusRequest.h"
#import "MCLUser.h"
#import "MCLBoard.h"
#import "MCLMessage.h"
#import "MCLRouter+mainNavigation.h"
#import "MCLRouter+composeMessage.h"
#import "MCLMessageListViewController.h"
#import "MCLComposeMessageViewController.h"
#import "MCLMessageToolbar.h"


@interface MCLMessageToolbarController ()

@property (weak, nonatomic) MCLMessageListViewController *messageListViewController;
@property (strong, nonatomic) MCLMessage *message;
@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) AVSpeechSynthesizer *speechSynthesizer;

@end

@implementation MCLMessageToolbarController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag messageListViewController:(MCLMessageListViewController *)messageListViewController
{
    self = [super init];
    if (!self) { return nil; }

    self.bag = bag;
    self.messageListViewController = messageListViewController;
    [self configure];

    return self;
}

#pragma mark - Configuration

- (void)configure
{
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[[WKWebViewConfiguration alloc] init]];
    self.speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    self.speechSynthesizer.delegate = self;
}

#pragma mark - Public

- (void)stopSpeaking
{
    if (self.speechSynthesizer.speaking) {
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
        self.toolbar.speakButton.image = [UIImage imageNamed:@"speakButton"];
    }
}

#pragma mark - MCLMessageToolbarDelegate

- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToOpenProfileFromUser:(MCLUser *)user
{
    [self.bag.router modalToProfileFromUser:user];
}

- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToCopyMessageLinkToClipboard:(MCLMessage *)message
{
    NSString *link = [NSString stringWithFormat:@"%@?mode=message&brdid=%@&msgid=%@", kManiacForumURL, message.board.boardId, message.messageId];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = link;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Copied link", nil)
                                                                   message:NSLocalizedString(@"URL for this message was copied to clipboard", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action) {
                                                   [alert dismissViewControllerAnimated:YES completion:nil];
                                               }];
    [alert addAction:ok];

    [self.messageListViewController presentViewController:alert animated:YES completion:nil];
}

- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToToggleNotificationButton:(UIBarButtonItem *)notificationButton
{
    MCLNotificationStatusRequest *request = [[MCLNotificationStatusRequest alloc] initWithClient:self.bag.httpClient
                                                                                         message:self.message];
    [request loadWithCompletionHandler:^(NSError *error, NSArray *json) {
        NSString *alertTitle, *alertMessage;
        if (error) {
            alertTitle = NSLocalizedString(@"Error", nil);
            alertMessage = [error localizedDescription];
        } else if (notificationButton.tag == 1) {
            [self.toolbar enableNotificationButton:NO];
            alertTitle = NSLocalizedString(@"Notification disabled", nil);
            alertMessage = NSLocalizedString(@"You will no longer receive Emails if anyone replies to this message", nil);
        } else {
            [notificationButton setTag:1];
            [self.toolbar enableNotificationButton:YES];
            alertTitle = NSLocalizedString(@"Notification enabled", nil);
            alertMessage = NSLocalizedString(@"You will receive an Email if anyone replies to this message", nil);
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                       message:alertMessage
                                                                preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [alert dismissViewControllerAnimated:YES completion:nil];
                                                         }];
        [alert addAction:okAction];

        [self.messageListViewController presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToSpeakMessage:(MCLMessage *)message
{
    if (self.speechSynthesizer.speaking) {
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
        self.toolbar.speakButton.image = [UIImage imageNamed:@"speakButton"];

        return;
    }

    [self.webView loadHTMLString:message.textHtml baseURL:nil];

    NSString *js1 = @"document.getElementsByTagName(\"html\")[0].innerHTML;";
    [self.webView evaluateJavaScript:js1 completionHandler:^(NSString *result, NSError *error) {
        if (error != nil) {
            NSLog(@"Error from WebView evaluating js1: %@", error);
            return;
        }

        // Remove quoted text (font tags)
        NSString *js2 = @"var fontTags = document.getElementsByTagName(\"font\");"
                        " for (var i=0; i < fontTags.length; x++) { fontTags[i].remove() };";
        [self.webView evaluateJavaScript:js2 completionHandler:^(NSString *result, NSError *error) {
            if (error) {
                NSLog(@"Error from WebView evaluating js2: %@", error);
            }
        }];

        NSString *js3 = @"document.getElementsByTagName(\"body\")[0].textContent;";
        [self.webView evaluateJavaScript:js3 completionHandler:^(NSString *result, NSError *error) {
            if (error != nil) {
                NSLog(@"Error from WebView evaluating js3: %@", error);
                return;
            }

            NSString *text = result;
            text = [[message.subject stringByAppendingString:@"... "] stringByAppendingString:text];
            text = [text stringByReplacingOccurrencesOfString: @"Re:" withString:@"Antwort auf... "];
            text = [text stringByReplacingOccurrencesOfString: @"m!client" withString:@"m! kleient"];
            text = [text stringByReplacingOccurrencesOfString: @"M!client" withString:@"m! kleient"];
            text = [text stringByReplacingOccurrencesOfString: @"iOS" withString:@"EI O S"];
            text = [[NSString stringWithFormat:@"Von %@... ", message.username] stringByAppendingString:text];

            [self speakText:text];
        }];
    }];
}

- (void)speakText:(NSString *)text
{
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"de-DE"]];

    [self.speechSynthesizer speakUtterance:utterance];
}

- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToEditMessage:(MCLMessage *)message
{
    [self.bag.router modalToEditMessage:message];
}

- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToReplyToMessage:(MCLMessage *)message
{
    MCLComposeMessageViewController *composeMessageVC = [self.bag.router modalToComposeReplyToMessage:message];
    composeMessageVC.delegate = self.messageListViewController;
}

#pragma mark - AVSpeechSynthesizerDelegate

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
    self.toolbar.speakButton.image = [UIImage imageNamed:@"stopButton"];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    self.toolbar.speakButton.image = [UIImage imageNamed:@"speakButton"];
}

@end