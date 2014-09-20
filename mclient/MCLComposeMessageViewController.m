//
//  MCLComposeMessageTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 31.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "constants.h"
#import "MCLComposeMessageViewController.h"
#import "MCLMServiceConnector.h"
#import "KeychainItemWrapper.h"

@interface MCLComposeMessageViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *composeSendButton;
@property (weak, nonatomic) IBOutlet UIButton *composeQuoteButton;
@property (weak, nonatomic) IBOutlet UITextField *composeSubjectTextField;
@property (weak, nonatomic) IBOutlet UITextView *composeTextTextField;

@end

@implementation MCLComposeMessageViewController

#define SUBJECT_MAXLENGTH 56

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.composeTextTextField.delegate = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

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
    
    NSArray *customMenuItems = @[[[UIMenuItem alloc] initWithTitle:@"B" action:@selector(formatBold:)],
                                 [[UIMenuItem alloc] initWithTitle:@"I" action:@selector(formatItalic:)],
                                 [[UIMenuItem alloc] initWithTitle:@"U" action:@selector(formatUnderline:)],
                                 [[UIMenuItem alloc] initWithTitle:@"S" action:@selector(formatStroke:)],
                                 [[UIMenuItem alloc] initWithTitle:@"Spoiler" action:@selector(formatSpoiler:)],
                                 [[UIMenuItem alloc] initWithTitle:@"Link" action:@selector(formatLink:)],
                                 [[UIMenuItem alloc] initWithTitle:@"IMG" action:@selector(formatImage:)]];
                                 
    [[UIMenuController sharedMenuController] setMenuItems:customMenuItems];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [self showTextViewCaretPosition:textView];
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    [self showTextViewCaretPosition:textView];
}


- (void)showTextViewCaretPosition:(UITextView *)textView {
    CGRect caretRect = [textView caretRectForPosition:self.composeTextTextField.selectedTextRange.end];
    [textView scrollRectToVisible:caretRect animated:NO];
}


#pragma mark - Keyboard notifications

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    BOOL isPortrait = UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    CGFloat keyboardHeight = isPortrait ? keyboardFrame.size.height : keyboardFrame.size.width;

    UIEdgeInsets contentInset = self.composeTextTextField.contentInset;
    contentInset.bottom = keyboardHeight;


    UIEdgeInsets scrollIndicatorInsets = self.composeTextTextField.scrollIndicatorInsets;
    scrollIndicatorInsets.bottom = keyboardHeight;

    [UIView animateWithDuration:animationDuration animations:^{
        self.composeTextTextField.contentInset = contentInset;
        self.composeTextTextField.scrollIndicatorInsets = scrollIndicatorInsets;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    UIEdgeInsets contentInset = self.composeTextTextField.contentInset;
    contentInset.bottom = 0;

    UIEdgeInsets scrollIndicatorInsets = self.composeTextTextField.scrollIndicatorInsets;
    scrollIndicatorInsets.bottom = 0;

    [UIView animateWithDuration:animationDuration animations:^{
        self.composeTextTextField.contentInset = contentInset;
        self.composeTextTextField.scrollIndicatorInsets = scrollIndicatorInsets;
    }];
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

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
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

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(formatBold:) ||
        action == @selector(formatItalic:) ||
        action == @selector(formatUnderline:) ||
        action == @selector(formatStroke:) ||
        action == @selector(formatSpoiler:) ||
        action == @selector(formatLink:) ||
        action == @selector(formatImage:)
    ) {
        return self.composeTextTextField.selectedRange.length > 0;
    }
    
    return NO;
}

- (IBAction)formatBold:(id)sender
{
    [self formatSelectionWith:@"[b:%@]"];
}

- (IBAction)formatItalic:(id)sender
{
    [self formatSelectionWith:@"[i:%@]"];
}

- (IBAction)formatUnderline:(id)sender
{
    [self formatSelectionWith:@"[u:%@]"];
}

- (IBAction)formatStroke:(id)sender
{
    [self formatSelectionWith:@"[s:%@]"];
}

- (IBAction)formatSpoiler:(id)sender
{
    [self formatSelectionWith:@"[h:%@]"];
}

- (IBAction)formatLink:(id)sender
{
    [self formatSelectionWith:@"[%@]"];
}

- (IBAction)formatImage:(id)sender
{
    [self formatSelectionWith:@"[img:%@]"];
}

- (void)formatSelectionWith:(NSString *)formatString
{
    NSRange range = [self.composeTextTextField selectedRange];
    NSString *selected = [self.composeTextTextField.text substringWithRange:range];
    
    NSString *textViewContent = self.composeTextTextField.text;
    NSString *replacement = [NSString stringWithFormat:formatString, selected];
    NSString *newContent = [textViewContent stringByReplacingCharactersInRange:range withString:replacement];
    self.composeTextTextField.text = newContent;
}

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
    
    switch (self.type) {
        case kComposeTypeThread:
            success = [mServiceConnector postThreadToBoardId:self.boardId
                                                     subject:self.composeSubjectTextField.text
                                                        text:self.composeTextTextField.text
                                                    username:username
                                                    password:password
                                                       error:&mServiceError];
            break;
        case kComposeTypeReply:
            success = [mServiceConnector postReplyToMessageId:self.messageId
                                                      boardId:self.boardId
                                                      subject:self.composeSubjectTextField.text
                                                         text:self.composeTextTextField.text
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
