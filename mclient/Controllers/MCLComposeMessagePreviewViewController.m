//
//  MCLPreviewMessageViewController.m
//  mclient
//
//  Created by Christopher Reitz on 26.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLComposeMessagePreviewViewController.h"

#import "constants.h"
#import "KeychainItemWrapper.h"
#import "Reachability.h"
#import "MCLAppDelegate.h"
#import "MCLMServiceConnector.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLLoadingView.h"
#import "MCLMServiceErrorView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLMessageListViewController.h"

@interface MCLComposeMessagePreviewViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UISwitch *notificationSwitch;
@property (weak, nonatomic) IBOutlet UILabel *notificationSwitchLabel;
@property (strong, nonatomic) NSString *previewText;

@end

@implementation MCLComposeMessagePreviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = self.subject;

    self.webView.delegate = self;

    if (self.type == kMCLComposeTypeEdit) {
        [self.notificationSwitch setHidden:YES];
        [self.notificationSwitchLabel setHidden:YES];
    }

    [self.sendButton setEnabled:NO];
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.view.frame]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] messagePreviewForBoardId:self.boardId
                                                                                         text:self.text
                                                                                        error:&mServiceError];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (mServiceError) {
                switch (mServiceError.code) {
                    case -2:
                        [self.view addSubview:[[MCLInternetConnectionErrorView alloc] initWithFrame:self.view.frame
                                                                                       hideSubLabel:YES]];
                        break;

                    default:
                        [self.view addSubview:[[MCLMServiceErrorView alloc] initWithFrame:self.view.frame
                                                                                  andText:[mServiceError localizedDescription]
                                                                             hideSubLabel:YES]];
                        break;
                }
            } else {
                [self.sendButton setEnabled:YES];

                NSString *key = @"";
                switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"showImages"]) {
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
                
                id <MCLTheme> currentTheme = [[MCLThemeManager sharedManager] currentTheme];
                self.previewText = [MCLMessageListViewController messageHtmlSkeletonForHtml:[data objectForKey:key]
                                                                              withTopMargin:20
                                                                                   andTheme:currentTheme];
                [self.webView loadHTMLString:self.previewText baseURL:nil];
            }
        });
    });
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

- (IBAction)sendAction:(id)sender
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
        KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
        NSString *username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
        NSData *passwordData = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
        NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];

        MCLMServiceConnector *mServiceConnector = [MCLMServiceConnector sharedConnector];
        NSError *mServiceError;

        switch (self.type) {
            case kMCLComposeTypeThread:
                [mServiceConnector postThreadToBoardId:self.boardId
                                               subject:self.subject
                                                  text:self.text
                                              username:username
                                              password:password
                                          notification:self.notificationSwitch.on
                                                 error:&mServiceError];
                break;
            case kMCLComposeTypeReply:
                [mServiceConnector postReplyToMessageId:self.messageId
                                                boardId:self.boardId
                                                threadId:self.threadId
                                                subject:self.subject
                                                   text:self.text
                                               username:username
                                               password:password
                                           notification:self.notificationSwitch.on
                                                  error:&mServiceError];
                break;
            case kMCLComposeTypeEdit:
                [mServiceConnector postEditToMessageId:self.messageId
                                               boardId:self.boardId
                                              threadId:self.threadId
                                               subject:self.subject
                                                  text:self.text
                                              username:username
                                              password:password
                                                 error:&mServiceError];
                break;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            if (mServiceError) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                            message:[mServiceError localizedDescription]
                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                  otherButtonTitles:nil] show];

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

                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Confirmation", nil)
                                                message:alertMessage
                                               delegate:nil
                                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                      otherButtonTitles:nil] show];
                }];
            }
        });
    });
}

@end
