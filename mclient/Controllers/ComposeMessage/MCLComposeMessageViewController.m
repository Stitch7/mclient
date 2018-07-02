//
//  MCLComposeMessageTableViewController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLComposeMessageViewController.h"

#import "UIViewController+Additions.h"
#import "MCLDependencyBag.h"
#import "MCLRouter+composeMessage.h"
#import "MCLSettings.h"
#import "MCLQuoteMessageRequest.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLComposeMessageToolbarController.h"
#import "MCLComposeMessagePreviewViewController.h"
#import "MCLComposeMessageViewControllerDelegate.h"
#import "MCLMessageTextViewToolbar.h"


@interface MCLComposeMessageViewController ()

@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIButton *quoteButton;
@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UITextField *subjectTextField;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorViewHeight;

@property (strong, nonatomic) MCLComposeMessageToolbarController *toolbarController;
@property (strong, nonatomic) UIBarButtonItem *previewButton;

@end

@implementation MCLComposeMessageViewController

#pragma mark - Initializers

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    [self configure];

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;

    [self configure];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Configuration

- (void)configure
{
    [self configureNotifications];
}

- (void)configureNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];
}

#pragma mark - UIViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureNavigationBar];

    // Color like in Apple Mail
    self.subjectLabel.textColor = [UIColor colorWithRed:142/255.0f green:142/255.0f blue:147/255.0f alpha:1.0f];

    [self configureSeparatorView];
    [self configureQuoteButton];
    [self configureSubjectField];
    [self configureTextField];

    [self themeChanged:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Workaround for greyed out preview button after push back (Bug in iOS11)
    self.navigationController.navigationBar.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
    self.navigationController.navigationBar.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
}

#pragma mark - Configuration

- (void)configureTitle
{
    self.title = [self.message actionTitle];
}

- (void)configureNavigationBar
{
    [self configureTitle];

    UIBarButtonItem *downButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"downButton"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(downButtonPressed)];
    self.navigationItem.leftBarButtonItem = downButton;

    self.previewButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Preview", nil)
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(previewButtonPressed)];
    self.navigationItem.rightBarButtonItem = self.previewButton;
}


- (void)configureSeparatorView
{
    self.separatorViewHeight.constant = 0.5;
}

- (void)configureQuoteButton
{
    BOOL isHidden = self.message.type == kMCLComposeTypeThread;
    [self.quoteButton setHidden:isHidden];
}

- (void)configureSubjectField
{
    self.subjectLabel.text = NSLocalizedString(@"Subject", nil);
    self.subjectTextField.delegate = self;

    if (self.message.subject) {
        self.subjectTextField.text = self.message.subject;
        [self.textView becomeFirstResponder];
    } else {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [self.subjectTextField becomeFirstResponder];
    }
}

- (void)configureTextField
{
    self.textView.themeManager = self.bag.themeManager;
    self.textView.errorHandler = self;
    if (self.message.type == kMCLComposeTypeEdit) {
        self.textView.text = self.message.text;
    }

    self.toolbarController = [[MCLComposeMessageToolbarController alloc] initWithParentViewController:self];
    MCLMessageTextViewToolbar *textViewToolbar = [[MCLMessageTextViewToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    textViewToolbar.messageTextViewToolbarDelegate = self.toolbarController;
    textViewToolbar.type = self.message.type;
    self.textView.inputAccessoryView = textViewToolbar;
}

#pragma mark - MCLMessageTextViewErrorHandler

- (void)invalidURLPasted
{
    [self presentErrorWithMessage:NSLocalizedString(@"Selected text is not a valid URL", nil)];
}

- (void)invalidImageURLPasted
{
    [self presentErrorWithMessage:NSLocalizedString(@"Selected text is not a valid image URL", nil)];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.subjectTextField) {
        [textField resignFirstResponder];
        [self.textView becomeFirstResponder];
    }
    
    return NO;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if (textField == self.subjectTextField) {
        self.previewButton.enabled = NO;
    }

    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL shouldChangeCharacters = YES;

    // Limit subject field to 56 characters
    if (textField == self.subjectTextField) {
        NSUInteger subjectMaxlength = 56;

        NSUInteger oldLength = [textField.text length];
        NSUInteger replacementLength = [string length];
        NSUInteger rangeLength = range.length;
        NSUInteger newLength = oldLength - rangeLength + replacementLength;

        // Disable send button if subject field is empty
        self.previewButton.enabled = newLength > 0;

        shouldChangeCharacters = newLength <= subjectMaxlength || [string rangeOfString: @"\n"].location != NSNotFound;
    }

    return shouldChangeCharacters;
}

#pragma mark - Actions

- (void)downButtonPressed
{
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)previewButtonPressed
{
    MCLComposeMessagePreviewViewController *previewVC = [self.bag.router pushToPreviewForMessage:[self buildMessage]];
    previewVC.delegate = self.delegate;
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    id <MCLTheme> currentTheme = self.bag.themeManager.currentTheme;
    self.view.backgroundColor = [currentTheme backgroundColor];
    self.separatorView.backgroundColor = [currentTheme tableViewSeparatorColor];
}

 #pragma mark - Private

- (MCLMessage *)buildMessage
{
    NSUInteger type = self.message.type ? self.message.type : kMCLComposeTypeThread;

    NSString *messageText = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (type == kMCLComposeTypeThread || type == kMCLComposeTypeReply) {
        BOOL signatureEnabled = [self.bag.settings isSettingActivated:MCLSettingSignatureEnabled orDefault:YES];
        if (signatureEnabled) {
            NSString *signature = [self.bag.settings objectForSetting:MCLSettingSignatureText
                                                            orDefault:kSettingsSignatureTextDefault];
            messageText = [messageText stringByAppendingString:@"\n\n"];
            messageText = [messageText stringByAppendingString:signature];
        }
    }

    MCLMessage *message = [MCLMessage messagePreviewWithType:type
                                                   messageId:self.message.messageId
                                                     boardId:self.message.boardId
                                                    threadId:self.message.thread.threadId
                                                     subject:self.subjectTextField.text
                                                        text:messageText];
    return message;
}

@end
