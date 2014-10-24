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
#import "MCLComposeMessagePreviewViewController.h"
#import "MCLMessageTextView.h"

@interface MCLComposeMessageViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *composePreviewButton;
@property (weak, nonatomic) IBOutlet UIButton *composeQuoteButton;
@property (weak, nonatomic) IBOutlet UILabel *composeSubjectLabel;
@property (weak, nonatomic) IBOutlet UITextField *composeSubjectTextField;
@property (weak, nonatomic) IBOutlet MCLMessageTextView *composeTextTextField;

@end

@implementation MCLComposeMessageViewController

#define SUBJECT_MAXLENGTH 56

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Subject label color like in Apple Mail
    self.composeSubjectLabel.textColor = [UIColor colorWithRed:142/255.0f green:142/255.0f blue:147/255.0f alpha:1.0f];

    switch (self.type) {
        case kMCLComposeTypeThread:
            self.title = NSLocalizedString(@"Create Thread", nil);
            [self.composeQuoteButton setHidden:YES];
            break;
        
        case kMCLComposeTypeReply:
            self.title = NSLocalizedString(@"Reply", nil);
            break;
            
        case kMCLComposeTypeEdit:
            self.title = NSLocalizedString(@"Edit", nil);
            [self.composeQuoteButton setHidden:YES];
            break;
    }

    // Widen subject field if preview button is absent
    if (self.composeQuoteButton.isHidden) {
        CGRect composeSubjectTextFieldFrame = self.composeSubjectTextField.frame;
        composeSubjectTextFieldFrame.size.width += self.composeQuoteButton.frame.size.width;
        self.composeSubjectTextField.frame = composeSubjectTextFieldFrame;
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

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.delegate handleRotationChangeInBackground];
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


- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if (textField == self.composeSubjectTextField) {
        self.composePreviewButton.enabled = NO;
    }

    return YES;
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
        self.composePreviewButton.enabled = newLength > 0;

        shouldChangeCharacters = newLength <= SUBJECT_MAXLENGTH || [string rangeOfString: @"\n"].location != NSNotFound;
    }

    return shouldChangeCharacters;
}


#pragma mark - Actions

- (IBAction)quoteButtonTouchUpInside:(UIButton *)sender
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] quoteMessageWithId:self.messageId fromBoardId:self.boardId error:&mServiceError];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            if (mServiceError) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                message:[mServiceError localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                NSString *textViewContent = [@"\n\n" stringByAppendingString:self.composeTextTextField.text];
                self.composeTextTextField.text = [[data objectForKey:@"quote"] stringByAppendingString:textViewContent];
            }
        });
    });
}

- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


 #pragma mark - Navigation

 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
     if ([segue.identifier isEqualToString:@"PushToPreview"]) {
         NSString *messageText = [self.composeTextTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

         if (self.type == kMCLComposeTypeThread || self.type == kMCLComposeTypeReply) {
             NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
             BOOL signatureEnabled = [userDefaults objectForKey:@"signatureEnabled"] == nil ? YES : [userDefaults boolForKey:@"signatureEnabled"];
             if (signatureEnabled) {
                 NSString *signature = [userDefaults objectForKey:@"signature"] ?: kSettingsSignatureTextDefault;
                 messageText = [messageText stringByAppendingString:@"\n\n"];
                 messageText = [messageText stringByAppendingString:signature];
             }
         }

         MCLComposeMessagePreviewViewController *destinationViewController = segue.destinationViewController;
         [destinationViewController setDelegate:self.delegate];
         [destinationViewController setType:self.type];
         [destinationViewController setBoardId:self.boardId];
         [destinationViewController setMessageId:self.messageId];
         [destinationViewController setSubject:self.composeSubjectTextField.text];
         [destinationViewController setText:messageText];
     }
 }


@end
