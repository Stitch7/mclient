//
//  MCLPreviewMessageViewController.m
//  mclient
//
//  Created by Christopher Reitz on 26.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLComposeMessagePreviewViewController.h"

#import "MCLMServiceConnector.h"
#import "KeychainItemWrapper.h"
#import "MCLErrorView.h"
#import "MCLLoadingView.h"
#import "MCLDetailViewController.h"

@interface MCLComposeMessagePreviewViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UISwitch *notificationSwitch;
@property (weak, nonatomic) IBOutlet UILabel *notificationSwitchLabel;
@property (strong, nonatomic) MCLMServiceConnector *mServiceConnector;

@end

@implementation MCLComposeMessagePreviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.mServiceConnector = [[MCLMServiceConnector alloc] init];
    self.title = self.subject;

    self.webView.delegate = self;

    if (self.type == kComposeTypeEdit) {
        [self.notificationSwitch setHidden:YES];
        [self.notificationSwitchLabel setHidden:YES];
    }

    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    NSString *username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    NSData *passwordData = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];

    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.view.bounds]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *content = [self.mServiceConnector previewForMessageId:self.messageId
                                                                    boardId:self.boardId
                                                                    subject:self.subject
                                                                       text:self.text
                                                                   username:username
                                                                   password:password
                                                                      error:&mServiceError];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id subview in self.view.subviews) {
                if ([[subview class] isSubclassOfClass: [MCLErrorView class]]) {
                    [subview removeFromSuperview];
                }
            }
            if ( ! mServiceError) {
                NSString *html = [MCLDetailViewController messageHtmlSkeletonForHtml:[content objectForKey:@"textHtmlWithImages"]];
                [self.webView loadHTMLString:html baseURL:nil];
            }
        });
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)sendAction:(id)sender
{
    BOOL success = NO;

    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    NSString *username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    NSData *passwordData = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
    NSError *mServiceError;

    NSString *messageText = self.text;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:@"signatureEnabled"]) {
        messageText = [messageText stringByAppendingString:@"\n\n"];
        messageText = [messageText stringByAppendingString:[userDefaults objectForKey:@"signature"]];
    }

    switch (self.type) {
        case kComposeTypeThread:
            success = [self.mServiceConnector postThreadToBoardId:self.boardId
                                                          subject:self.subject
                                                             text:messageText
                                                         username:username
                                                         password:password
                                                     notification:self.notificationSwitch.on
                                                            error:&mServiceError];
            break;
        case kComposeTypeReply:
            success = [self.mServiceConnector postReplyToMessageId:self.messageId
                                                           boardId:self.boardId
                                                           subject:self.subject
                                                              text:messageText
                                                          username:username
                                                          password:password
                                                      notification:self.notificationSwitch.on
                                                             error:&mServiceError];
            break;
        case kComposeTypeEdit:
            success = [self.mServiceConnector postEditToMessageId:self.messageId
                                                          boardId:self.boardId
                                                          subject:self.subject
                                                             text:self.text
                                                         username:username
                                                         password:password
                                                            error:&mServiceError];
            break;
    }

    if (success) {
        dispatch_block_t completion = ^{
            [self.delegate composeMessageViewControllerDidFinish:self];

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                            message:@"Message was posted"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        };

        [self dismissViewControllerAnimated:YES completion:completion];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[mServiceError localizedDescription]
                                                        message:[mServiceError localizedFailureReason]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}


@end
