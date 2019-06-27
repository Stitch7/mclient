//
//  MCLMessageToolbarController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageToolbarController.h"

@import WebKit;

#import "UIViewController+Additions.h"
#import "MCLDependencyBag.h"
#import "MCLSoundEffectPlayer.h"
#import "MCLNotificationRequest.h"
#import "MCLUser.h"
#import "MCLBoard.h"
#import "MCLMessage.h"
#import "MCLRouter+mainNavigation.h"
#import "MCLRouter+composeMessage.h"
#import "MCLEditTextRequest.h"
#import "MCLMessageListViewController.h"
#import "MCLComposeMessageViewController.h"
#import "MCLMessageToolbar.h"


@interface MCLMessageToolbarController ()

@property (weak, nonatomic) MCLMessageListViewController *messageListViewController;
@property (strong, nonatomic) MCLMessage *message;
@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) AVSpeechSynthesizer *speechSynthesizer;
@property (assign, nonatomic) BOOL loadingForEdit;

@end

@implementation MCLMessageToolbarController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag messageListViewController:(MCLMessageListViewController *)messageListViewController
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;
    self.messageListViewController = messageListViewController;
    self.loadingForEdit = NO;
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
    }
}

#pragma mark - MCLMessageToolbarDelegate

- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToOpenProfileFromUser:(MCLUser *)user
{
    [self.bag.router modalToProfileFromUser:user];
}

- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToCopyMessageLinkToClipboard:(MCLMessage *)message
{
    NSString *link = [NSString stringWithFormat:@"%@forum/pxmboard.php?mode=message&brdid=%@&msgid=%@", kManiacForumURL, message.board.boardId, message.messageId];
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

    [self.bag.soundEffectPlayer playCopyLinkSound];
    [self.messageListViewController presentViewController:alert animated:YES completion:nil];
}

- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToToggleNotificationButton:(UIBarButtonItem *)notificationButton forMessage:(MCLMessage *)message withCompletionHandler:(void (^)(void))completionHandler
{
    MCLNotificationRequest *request = [[MCLNotificationRequest alloc] initWithClient:self.bag.httpClient
                                                                             message:message];
    [request loadWithCompletionHandler:^(NSError *error, NSArray *json) {
        NSString *alertTitle, *alertMessage;
        if (error) {
            alertTitle = NSLocalizedString(@"Error", nil);
            alertMessage = [error localizedDescription];
        } else if (notificationButton.tag == 1) {
            [toolbar enableNotificationButton:NO];
            alertTitle = NSLocalizedString(@"Notification disabled", nil);
            alertMessage = NSLocalizedString(@"You will no longer receive Emails if anyone replies to this message", nil);
        } else {
            [toolbar enableNotificationButton:YES];
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

        if (completionHandler) {
            completionHandler();
        }
        [self.messageListViewController presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToSpeakMessage:(MCLMessage *)message
{
    self.toolbar = toolbar;

    if (self.speechSynthesizer.speaking) {
        [self stopSpeaking];

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
    if (self.loadingForEdit) {
        return;
    }

    self.loadingForEdit = YES;
    MCLEditTextRequest *request = [[MCLEditTextRequest alloc] initWithClient:self.bag.httpClient message:message];
    [request loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        self.loadingForEdit = NO;
        if (error) {
            [self.bag.router.masterNavigationController presentError:error];
            return;
        }

        message.text = [[data firstObject] objectForKey:@"editText"];
        MCLComposeMessageViewController *composeMessageVC = [self.bag.router modalToEditMessage:message];
        composeMessageVC.delegate = self.messageListViewController;
    }];
}

- (void)messageToolbar:(MCLMessageToolbar *)toolbar requestsToReplyToMessage:(MCLMessage *)message
{
    if (message.userBlockedYou || message.userBlockedByYou) {
        NSString *title = message.userBlockedYou
            ? NSLocalizedString(@"You have been blocked by this user", nil)
            : NSLocalizedString(@"User was blocked by you", nil);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:NSLocalizedString(@"You cannot reply to this post", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
        [alert addAction:ok];
        [self.messageListViewController presentViewController:alert animated:YES completion:nil];
    } else {
        MCLComposeMessageViewController *composeMessageVC = [self.bag.router modalToComposeReplyToMessage:message];
        composeMessageVC.delegate = self.messageListViewController;
    }
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

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance
{
    self.toolbar.speakButton.image = [UIImage imageNamed:@"speakButton"];
}

@end
