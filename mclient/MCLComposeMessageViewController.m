//
//  MCLComposeMessageTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 31.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLComposeMessageViewController.h"

#import "constants.h"
#import "MCLMServiceConnector.h"
#import "KeychainItemWrapper.h"
#import "MCLMessageTextView.h"

@interface MCLComposeMessageViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *composeSendButton;
@property (weak, nonatomic) IBOutlet UIButton *composeQuoteButton;
@property (weak, nonatomic) IBOutlet UITextField *composeSubjectTextField;
@property (weak, nonatomic) IBOutlet MCLMessageTextView *composeTextTextField;

@end

@implementation MCLComposeMessageViewController

#define SUBJECT_MAXLENGTH 56

- (void)viewDidLoad
{
    [super viewDidLoad];

    switch (self.type) {
        case kComposeTypeThread:
            self.title = @"Create Thread";
            [self.composeQuoteButton setHidden:YES];
            break;
        
        case kComposeTypeReply:
            self.title = @"Reply";
            break;
            
        case kComposeTypeEdit:
            self.title = @"Edit";
            [self.composeQuoteButton setHidden:YES];
            break;
    }
    
    self.composeSubjectTextField.delegate = self;
    if (self.subject) {
        self.composeSubjectTextField.text = self.subject;
        [self.composeTextTextField becomeFirstResponder];
    } else {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [self.composeSubjectTextField becomeFirstResponder];
    }
    
    if (self.text) {
        self.composeTextTextField.text = self.text;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.composeSubjectTextField) {
        [textField resignFirstResponder];
        [self.composeTextTextField becomeFirstResponder];
    }
    
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL shouldChangeCharacters = YES;

    // Limit subject field to characters defined in SUBJECT_MAXLENGTH
    if (textField == self.composeSubjectTextField) {
        NSUInteger oldLength = [textField.text length];
        NSUInteger replacementLength = [string length];
        NSUInteger rangeLength = range.length;

        NSUInteger newLength = oldLength - rangeLength + replacementLength;

        // Disable send button if subject field is empty
        self.composeSendButton.enabled = newLength > 0;

        shouldChangeCharacters = newLength <= SUBJECT_MAXLENGTH || [string rangeOfString: @"\n"].location != NSNotFound;
    }

    return shouldChangeCharacters;
}


#pragma mark - Actions

- (IBAction)quoteButtonTouchUpInside:(UIButton *)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *urlString = [kMServiceBaseURL stringByAppendingString:[NSString stringWithFormat:@"/board/%@/quote/%@", self.boardId, self.messageId]];
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        [self performSelectorOnMainThread:@selector(fetchQuoteData:) withObject:data waitUntilDone:YES];
    });
}

- (void)fetchQuoteData:(NSData *)responseData
{
    NSError* error;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];

    if (error == nil) {
        NSString *textViewContent = [@"\n\n" stringByAppendingString:self.composeTextTextField.text];
        self.composeTextTextField.text = [[json objectForKey:@"quote"] stringByAppendingString:textViewContent];
    } else {
        NSLog(@"ERROR!");
    }
}

- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveAction:(id)sender
{
    BOOL success = NO;
    MCLMServiceConnector *mServiceConnector = [[MCLMServiceConnector alloc] init];

    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    NSString *username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    NSData *passwordData = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
    NSError *mServiceError;

    NSString *messageText = self.composeTextTextField.text;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:@"signatureEnabled"]) {
        messageText = [messageText stringByAppendingString:@"\n\n"];
        messageText = [messageText stringByAppendingString:[userDefaults objectForKey:@"signature"]];
    }
    
    switch (self.type) {
        case kComposeTypeThread:
            success = [mServiceConnector postThreadToBoardId:self.boardId
                                                     subject:self.composeSubjectTextField.text
                                                        text:messageText
                                                    username:username
                                                    password:password
                                                       error:&mServiceError];
            break;
        case kComposeTypeReply:
            success = [mServiceConnector postReplyToMessageId:self.messageId
                                                      boardId:self.boardId
                                                      subject:self.composeSubjectTextField.text
                                                         text:messageText
                                                     username:username
                                                     password:password
                                                        error:&mServiceError];
            break;
        case kComposeTypeEdit:
            success = [mServiceConnector postEditToMessageId:self.messageId
                                                     boardId:self.boardId
                                                     subject:self.composeSubjectTextField.text
                                                        text:self.composeTextTextField.text
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
