//
//  MCLComposeMessageTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 31.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLComposeMessageTableViewController.h"
#import "MCLMServiceConnector.h"
#import "KeychainItemWrapper.h"

@interface MCLComposeMessageTableViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *composeCancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *composeSendButton;
@property (weak, nonatomic) IBOutlet UITextField *composeSubjectTextField;
@property (weak, nonatomic) IBOutlet UITextView *composeTextTextField;

@end

@implementation MCLComposeMessageTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        // Custom initialization
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    
    switch (self.type) {
        case kComposeTypeThread:
            self.title = @"Create Thread";
            break;
        
        case kComposeTypeReply:
            self.title = @"Reply";
            break;
            
        case kComposeTypeEdit:
            self.title = @"Edit";
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
    NSUInteger length = self.composeSubjectTextField.text.length - range.length + string.length;
    if (length > 0) {
        self.composeSendButton.enabled = YES;
    } else {
        self.composeSendButton.enabled = NO;
    }
    
    return YES;
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





- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveAction:(id)sender
{
    MCLMServiceConnector *mServiceConnector = [[MCLMServiceConnector alloc] init];

    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"M!client" accessGroup:nil];
    NSString *username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    NSData *passwordData = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
    
    switch (self.type) {
        case kComposeTypeThread:
            [mServiceConnector postThreadToBoardId:self.boardId
                                           subject:self.composeSubjectTextField.text
                                              text:self.composeTextTextField.text
                                          username:username
                                          password:password
                                      notification:@1];
            break;
        case kComposeTypeReply:
            [mServiceConnector postReplyToMessageId:self.messageId
                                            boardId:self.boardId
                                            subject:self.composeSubjectTextField.text
                                               text:self.composeTextTextField.text
                                           username:username
                                           password:password
                                       notification:@0];
            break;
        case kComposeTypeEdit:
            [mServiceConnector postEditToMessageId:self.messageId
                                            boardId:self.boardId
                                            subject:self.composeSubjectTextField.text
                                               text:self.composeTextTextField.text
                                           username:username
                                           password:password];
            break;
    }
    
    
}

@end
