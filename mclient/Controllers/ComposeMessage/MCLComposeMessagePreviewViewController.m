//
//  MCLPreviewMessageViewController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLComposeMessagePreviewViewController.h"

#import "Reachability.h"
#import "MCLDependencyBag.h"
#import "MCLHTTPClient.h"
#import "MCLSettings.h"
#import "MCLPreviewMessageRequest.h"
#import "MCLLogin.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLLoadingView.h"
#import "MCLMServiceErrorView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLMessageListViewController.h"
#import "MCLMessage.h"

@interface MCLComposeMessagePreviewViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UISwitch *notificationSwitch;
@property (weak, nonatomic) IBOutlet UILabel *notificationSwitchLabel;
@property (strong, nonatomic) UIBarButtonItem *sendButton;
@property (strong, nonatomic) NSString *previewText;

@end

@implementation MCLComposeMessagePreviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureNavigationBar];

    self.webView.delegate = self;

    if (self.type == kMCLComposeTypeEdit) {
        [self.notificationSwitch setHidden:YES];
        [self.notificationSwitchLabel setHidden:YES];
    }

    [self.sendButton setEnabled:NO];
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.view.frame]];

    MCLMessage *message = [[MCLMessage alloc] init];
    message.boardId = self.boardId;
    message.text = self.text;

    [[[MCLPreviewMessageRequest alloc] initWithClient:self.bag.httpClient message:message] loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        if (error) {
            switch (error.code) {
                case -2:
                    [self.view addSubview:[[MCLInternetConnectionErrorView alloc] initWithFrame:self.view.frame
                                                                                   hideSubLabel:YES]];
                    break;

                default:
                    [self.view addSubview:[[MCLMServiceErrorView alloc] initWithFrame:self.view.frame
                                                                              andText:[error localizedDescription]
                                                                         hideSubLabel:YES]];
                    break;
            }
        } else {
            [self.sendButton setEnabled:YES];

            NSString *key = @"";
            switch ([self.bag.settings integerForSetting:MCLSettingShowImages]) {
                case kMCLSettingsShowImagesWifi: {
                    Reachability *wifiReach = [Reachability reachabilityForLocalWiFi];
                    key = [wifiReach currentReachabilityStatus] == ReachableViaWiFi
                    ? @"previewTextHtmlWithImages"
                    : @"previewTextHtml";
                    break;
                }
                case kMCLSettingsShowImagesNever:
                    key = @"previewTextHtml";
                    break;

                case kMCLSettingsShowImagesAlways:
                default:
                    key = @"previewTextHtmlWithImages";
                    break;
            }

            MCLMessage *previewMessage = [[MCLMessage alloc] init];
            previewMessage.textHtml = [[data firstObject] objectForKey:key];
            previewMessage.textHtmlWithImages = previewMessage.textHtml;
            self.previewText = [previewMessage messageHtmlWithTopMargin:20
                                                               andTheme:[self.bag.themeManager currentTheme]];
            [self.webView loadHTMLString:self.previewText baseURL:nil];
        }
    }];
}

#pragma mark - Configuration

- (void)configureNavigationBar
{
    self.title = self.subject;
    self.sendButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", nil)
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(sendButtonPressed:)];
    self.navigationItem.rightBarButtonItem = self.sendButton;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // UIWebView object has fully loaded.
    if ([[webView stringByEvaluatingJavaScriptFromString:@"document.readyState"] isEqualToString:@"complete"]) {
        for (id subview in self.view.subviews) {
            if ([[subview class] isSubclassOfClass: [MCLLoadingView class]]) {
                [subview removeFromSuperview];
            }
        }
    }
}

#pragma mark - Actions

- (void)sendButtonPressed:(id)sender
{
    id completionHandler = ^(NSError *error, NSDictionary *data) {
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                           message:[error localizedDescription]
                                                                    preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * action) {
                                                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                                             }];
            [alert addAction:okAction];

            [self presentViewController:alert animated:YES completion:nil];
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                if ([self.delegate respondsToSelector:@selector(handleRotationChangeInBackground)]) {
                    [self.delegate handleRotationChangeInBackground];
                }
                [self.delegate messageSentWithType:self.type];

                NSString *alertMessage;
                if (self.type == kMCLComposeTypeEdit) {
                    alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Your message \"%@\" was changed", nil), self.subject];
                } else {
                    alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Thank you for your contribution \"%@\"", nil), self.subject];
                }

                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirmation", nil)
                                                                               message:alertMessage
                                                                        preferredStyle:UIAlertControllerStyleAlert];

                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * action) {
                                                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                                                 }];
                [alert addAction:okAction];

                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
    };

    switch (self.type) {
        case kMCLComposeTypeThread: {
            NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message", kMServiceBaseURL, self.boardId];
            NSDictionary *vars = @{@"subject":self.subject,
                                   @"text":self.text,
                                   @"notification":[NSString stringWithFormat:@"%d", self.notificationSwitch.on]};
            [self.bag.httpClient postRequestToUrlString:urlString
                                               withVars:vars
                                             needsLogin:YES
                                      completionHandler:completionHandler];
            break;
        }
        case kMCLComposeTypeReply: {
            NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message/%@",
                                   kMServiceBaseURL, self.boardId, self.messageId];
            NSDictionary *vars = @{@"threadId":[self.threadId stringValue],
                                   @"subject":self.subject,
                                   @"text":self.text,
                                   @"notification":[NSString stringWithFormat:@"%d", self.notificationSwitch.on]};
            [self.bag.httpClient postRequestToUrlString:urlString
                                               withVars:vars
                                             needsLogin:YES
                                      completionHandler:completionHandler];
            break;
        }
        case kMCLComposeTypeEdit: {
            NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message/%@",
                                   kMServiceBaseURL, self.boardId, self.messageId];
            NSDictionary *vars = @{@"threadId":[self.threadId stringValue],
                                   @"subject":self.subject,
                                   @"text":self.text};
            [self.bag.httpClient putRequestToUrlString:urlString
                                              withVars:vars
                                            needsLogin:YES
                                     completionHandler:completionHandler];
            break;
        }
    }
}

@end
