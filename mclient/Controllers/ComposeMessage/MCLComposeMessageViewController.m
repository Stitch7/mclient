//
//  MCLComposeMessageTableViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLComposeMessageViewController.h"

#import "UIViewController+Additions.h"
#import "MCLDependencyBag.h"
#import "MCLFeatures.h"
#import "MCLRouter+composeMessage.h"
#import "MCLSettings.h"
#import "MCLQuoteMessageRequest.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLDraftManager.h"
#import "MCLDraft.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLComposeMessageToolbarController.h"
#import "MCLComposeMessagePreviewViewController.h"
#import "MCLComposeMessageViewControllerDelegate.h"
#import "MCLTextField.h"
#import "MCLMessageTextViewToolbar.h"


@interface MCLComposeMessageViewController ()

@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet MCLTextField *subjectTextField;
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

    [self loadDraftIfExists];

    [self configureNavigationBar];
    [self configureSeparatorView];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    [self saveAsDraftIfEdited];
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

- (void)configureSubjectField
{
    // Color like in Apple Mail
    self.subjectLabel.textColor = [UIColor colorWithRed:142/255.0f green:142/255.0f blue:147/255.0f alpha:1.0f];
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
    if (self.message.type == kMCLComposeTypeEdit || self.message.isDraft) {
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

    if ([self.bag.features isFeatureWithNameEnabled:MCLFeatureDrafts] && [self wasEdited]) {
        [self askForDraftAndDismiss];
    } else {
        [self dismiss];
    }
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate composeMessageViewController:self dismissedWithMessage:[self buildMessageWithSignature:YES]];
    }];
}

- (void)previewButtonPressed
{
    MCLComposeMessagePreviewViewController *previewVC = [self.bag.router pushToPreviewForMessage:[self buildMessageWithSignature:YES]];
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

- (BOOL)wasEdited
{
    return self.textView.changed;
}

- (void)loadDraftIfExists
{
    if (self.message && self.message.type == kMCLComposeTypeEdit) {
        return;
    }

    MCLMessage *draftMessage = [self.bag.draftManager draftForMessage:self.message];
    if (draftMessage) {
        self.message = draftMessage;
    }
}

- (void)askForDraftAndDismiss
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Save as draft?", nil)
                                                                   message:NSLocalizedString(@"Do you want to keep your message and continue editing later?", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Save", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                [self saveAsDraft];
                                                [self dismiss];
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Discard", nil)
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                [self dismiss];
                                            }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)saveAsDraftIfEdited
{
    if (![self.bag.features isFeatureWithNameEnabled:MCLFeatureDrafts]) {
        return;
    }

    if ([self wasEdited]) {
        [self saveAsDraft];
    }
}

- (void)saveAsDraft
{
    [self.bag.draftManager saveMessageAsDraft:[self buildMessageWithSignature:NO]];
}

- (MCLMessage *)buildMessageWithSignature:(BOOL)appendSignature
{
    NSUInteger type = self.message.type ? self.message.type : kMCLComposeTypeThread;

    NSString *messageText = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (appendSignature && (type == kMCLComposeTypeThread || type == kMCLComposeTypeReply)) {
        BOOL signatureEnabled = [self.bag.settings isSettingActivated:MCLSettingSignatureEnabled orDefault:YES];
        if (signatureEnabled) {
            NSString *signature = [self.bag.settings objectForSetting:MCLSettingSignatureText
                                                            orDefault:kSettingsSignatureTextDefault];
            if (![messageText hasSuffix:signature]) {
                messageText = [messageText stringByAppendingString:@"\n\n"];
                messageText = [messageText stringByAppendingString:signature];
            }
        }
    }

    MCLMessage *message = [MCLMessage messagePreviewWithType:type
                                                   messageId:self.message.messageId
                                                       board:self.message.board
                                                    threadId:self.message.thread.threadId
                                                     subject:self.subjectTextField.text
                                                        text:messageText];
    message.prevMessage = self.message;
    return message;
}

@end
