//
//  MCLComposeMessageTableViewController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLComposeMessageViewController.h"

@import AVFoundation;

#import "ImgurSession.h"
#import "MRProgressOverlayView.h"

#import "MCLDependencyBag.h"
#import "MCLSettings.h"
#import "MCLQuoteMessageRequest.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLMessage.h"
#import "MCLComposeMessagePreviewViewController.h"
#import "MCLComposeMessageViewControllerDelegate.h"
#import "MCLMessageTextViewToolbar.h"

@interface MCLComposeMessageViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIButton *composeQuoteButton;
@property (weak, nonatomic) IBOutlet UILabel *composeSubjectLabel;
@property (weak, nonatomic) IBOutlet UITextField *composeSubjectTextField;
@property (weak, nonatomic) IBOutlet UIView *composeSeparatorView;
@property (weak, nonatomic) IBOutlet MCLMessageTextView *composeTextTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorViewHeight;

@property (strong, nonatomic) UIBarButtonItem *composePreviewButton;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) MRProgressOverlayView *progressView;

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
    [self configureProgressView];

    // Color like in Apple Mail
    self.composeSubjectLabel.textColor = [UIColor colorWithRed:142/255.0f green:142/255.0f blue:147/255.0f alpha:1.0f];

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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if ([self.delegate respondsToSelector:@selector(handleRotationChangeInBackground)]) {
        [self.delegate handleRotationChangeInBackground];
    }
}

#pragma mark - Configuration

- (void)configureTitle
{
    switch (self.type) {
        case kMCLComposeTypeThread:
            self.title = NSLocalizedString(@"Create Thread", nil);
            break;

        case kMCLComposeTypeReply:
            self.title = NSLocalizedString(@"Reply", nil);
            break;

        case kMCLComposeTypeEdit:
            self.title = NSLocalizedString(@"Edit", nil);
            break;
    }
}

- (void)configureNavigationBar
{
    [self configureTitle];

    UIBarButtonItem *downButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"downButton"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(downButtonPressed)];
    self.navigationItem.leftBarButtonItem = downButton;

    self.composePreviewButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Preview", nil)
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(previewButtonPressed)];
    self.navigationItem.rightBarButtonItem = self.composePreviewButton;
}

- (void)configureProgressView
{
    self.progressView = [MRProgressOverlayView new];
    self.progressView.mode = MRProgressOverlayViewModeDeterminateCircular;
    self.progressView.titleLabelText = @"Uploading";
    [self.view addSubview:self.progressView];
}

- (void)configureSeparatorView
{
    self.separatorViewHeight.constant = 0.5;
}

- (void)configureQuoteButton
{
    BOOL isHidden = self.type == kMCLComposeTypeThread;
    [self.composeQuoteButton setHidden:isHidden];
}

- (void)configureSubjectField
{
    self.composeSubjectLabel.text = NSLocalizedString(@"Subject", nil);
    self.composeSubjectTextField.delegate = self;

    if (self.subject) {
        self.composeSubjectTextField.text = self.subject;
        [self.composeTextTextField becomeFirstResponder];
    } else {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [self.composeSubjectTextField becomeFirstResponder];
    }
}

- (void)configureTextField
{
    self.composeTextTextField.themeManager = self.bag.themeManager;
    self.composeTextTextField.errorHandler = self;
    self.composeTextTextField.text = self.text;

    MCLMessageTextViewToolbar *textViewToolbar = [[MCLMessageTextViewToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    textViewToolbar.messageTextViewToolbarDelegate = self;
    textViewToolbar.type = self.type;
    self.composeTextTextField.inputAccessoryView = textViewToolbar;
}

#pragma mark - MCLMessageTextViewErrorHandler

- (void)invalidURLPasted
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                   message:NSLocalizedString(@"Selected text is not a valid URL", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                                     }];
    [alert addAction:okAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)invalidImageURLPasted
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                   message:NSLocalizedString(@"Selected text is not a valid image URL", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                                     }];
    [alert addAction:okAction];

    [self presentViewController:alert animated:YES completion:nil];
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

    // Limit subject field to 56 characters
    if (textField == self.composeSubjectTextField) {
        NSUInteger subjectMaxlength = 56;

        NSUInteger oldLength = [textField.text length];
        NSUInteger replacementLength = [string length];
        NSUInteger rangeLength = range.length;
        NSUInteger newLength = oldLength - rangeLength + replacementLength;

        // Disable send button if subject field is empty
        self.composePreviewButton.enabled = newLength > 0;

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
    [self performSegueWithIdentifier:@"PushToPreview" sender:nil];
}

#pragma mark - MCLMessageTextViewToolbarDelegate

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar boldButtonPressed:(UIBarButtonItem *)sender
{
    [self.composeTextTextField formatBold];
}

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar italicButtonPressed:(UIBarButtonItem *)sender
{
    [self.composeTextTextField formatItalic];
}

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar underlineButtonPressed:(UIBarButtonItem *)sender
{
    [self.composeTextTextField formatUnderline];
}

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar strikestroughButtonPressed:(UIBarButtonItem *)sender
{
    [self.composeTextTextField formatStroke];
}

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar spoilerButtonPressed:(UIBarButtonItem *)sender
{
    [self.composeTextTextField formatSpoiler];
}

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar cameraButtonPressed:(UIBarButtonItem *)sender;
{
    [self.composeTextTextField resignFirstResponder];

    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil
                                                                         message:nil //@"Bild hinzufügen"
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];

    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Abbrechen" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.composeTextTextField becomeFirstResponder];
    }]];

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Foto aufnehmen" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self showCamera:sender];
        }]];
    }

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Aus Album auswählen" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self showPhotoPicker:sender];
        }]];
    }

    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)showCamera:(id)sender
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusDenied) {
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:@"Unable to access the Camera"
                                            message:@"To enable access, go to Settings > Privacy > Camera and turn on Camera access for this app."
                                     preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];

        [self presentViewController:alertController animated:YES completion:nil];
    }
    else if (authStatus == AVAuthorizationStatusNotDetermined)
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera fromButton:sender];
            }
        }];
    else {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera fromButton:sender];
    }
}

- (void)showPhotoPicker:(id)sender
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary fromButton:sender];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType fromButton:(UIBarButtonItem *)button
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    imagePickerController.modalPresentationStyle =
    (sourceType == UIImagePickerControllerSourceTypeCamera) ? UIModalPresentationFullScreen : UIModalPresentationPopover;

    UIPopoverPresentationController *presentationController = imagePickerController.popoverPresentationController;
    presentationController.barButtonItem = button;
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;

    self.imagePickerController = imagePickerController;

    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar quoteButtonPressed:(UIBarButtonItem *)sender
{
    [sender setEnabled:NO];

    MCLMessage *message = [[MCLMessage alloc] init];
    message.boardId = self.boardId;
    message.messageId = self.messageId;

    MCLQuoteMessageRequest *request = [[MCLQuoteMessageRequest alloc] initWithClient:self.bag.httpClient
                                                                             message:message];
    [request loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                           message:[error localizedDescription]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction * action) {
                                                        [alert dismissViewControllerAnimated:YES completion:nil];
                                                    }]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            NSString *quoteString = [[data firstObject] objectForKey:@"quote"];
            NSArray *rawQuoteBlocks = [quoteString componentsSeparatedByString:@"\n"];
            NSMutableArray *quoteBlocks = [[NSMutableArray alloc] init];
            BOOL quoteOfQuoteRemoved = NO;
            for (NSString *rawQuoteBlock in rawQuoteBlocks) {
                if ([rawQuoteBlock isEqualToString:@">"] ||
                    [rawQuoteBlock hasPrefix:@">>"] ||
                    [rawQuoteBlock hasPrefix:@">-------------"] ||
                    [[rawQuoteBlock lowercaseString] hasPrefix:@">gesendet mit"]) {
                    quoteOfQuoteRemoved = YES;
                    continue;
                }
                [quoteBlocks addObject:rawQuoteBlock];
            }

            if ([quoteBlocks count] == 1 && !quoteOfQuoteRemoved) {
                NSString *textViewContent = [@"\n\n" stringByAppendingString:self.composeTextTextField.text];
                self.composeTextTextField.text = [quoteString stringByAppendingString:textViewContent];
            }
            else {
                [self presentQuotePickerActionSheet:quoteBlocks quoteString:quoteString];
            }
        }
        [sender setEnabled:YES];
    }];
}

- (void)presentQuotePickerActionSheet:(NSMutableArray *)quoteBlocks quoteString:(NSString *)quoteString
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select quote", nil)
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    for (NSString *quoteBlock in quoteBlocks) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:[quoteBlock substringFromIndex:1]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           NSString *textViewContent = self.composeTextTextField.text;
                                                           if (textViewContent.length > 0) {
                                                               textViewContent = [textViewContent stringByAppendingString:@"\n\n"];
                                                           }
                                                           self.composeTextTextField.text = [[textViewContent stringByAppendingString:quoteBlock] stringByAppendingString:@"\n"];
                                                       }];
        [alert addAction:action];
    }

    UIAlertAction *fullQuoteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Full quote", nil)
                                                              style:UIAlertActionStyleDestructive
                                                            handler:^(UIAlertAction * action) {
                                                                NSString *textViewContent = [@"\n\n" stringByAppendingString:self.composeTextTextField.text];
                                                                self.composeTextTextField.text = [quoteString stringByAppendingString:textViewContent];
                                                            }];
    [alert addAction:fullQuoteAction];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.7f);

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [IMGImageRequest uploadImageWithData:imageData
                                   title:self.subject
                                progress:^(NSProgress *progress) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [self.progressView setProgress:(float)progress.fractionCompleted animated:YES];
                                    });
                                }
                                 success:^(IMGImage *image) {
                                     [self dissmissProgressViewWithSuccess:YES completionHandler:^{
                                         [self.composeTextTextField addImage:image.url];
                                     }];
                                 }
                                 failure:^(NSURLSessionDataTask *task, NSError *error) {
                                     [self dissmissProgressViewWithSuccess:YES completionHandler:^{
                                         NSLog(@"Imgur upload error: %@", error);
                                         UIAlertController *alert = [UIAlertController
                                                                     alertControllerWithTitle:@"Imgur upload error"
                                                                     message:error.localizedDescription
                                                                     preferredStyle:UIAlertControllerStyleAlert];

                                         UIAlertAction *yesButton = [UIAlertAction
                                                                     actionWithTitle:@"OK"
                                                                     style:UIAlertActionStyleDefault
                                                                     handler:nil];
                                         [alert addAction:yesButton];

                                         [self.view endEditing:YES];
                                         [self presentViewController:alert animated:YES completion:nil];
                                     }];
                                 }];
    self.imagePickerController = nil;

    [self dismissViewControllerAnimated:YES completion:^{
        [self.progressView show:YES];
    }];
}

- (void)dissmissProgressViewWithSuccess:(BOOL)success completionHandler:(void(^)(void))completion
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if (success) {
        self.progressView.mode = MRProgressOverlayViewModeCheckmark;
        self.progressView.titleLabelText = @"Succeed";
    } else {
        self.progressView.mode = MRProgressOverlayViewModeCross;
        self.progressView.titleLabelText = @"Failed";
    }

    completion();

    [self performBlock:^{
        [self.progressView dismiss:YES completion:^{
            self.progressView.mode = MRProgressOverlayViewModeDeterminateCircular;
            self.progressView.titleLabelText = @"Uploading";
            self.progressView.progress = 0;

            if (success) {
                [self.composeTextTextField becomeFirstResponder];
            }
        }];
    } afterDelay:0.5];
}

- (void)performBlock:(void(^)(void))block afterDelay:(NSTimeInterval)delay
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    self.imagePickerController = nil;

    [self dismissViewControllerAnimated:YES completion:^{
        [self.composeTextTextField becomeFirstResponder];
    }];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    id <MCLTheme> currentTheme = self.bag.themeManager.currentTheme;
    self.view.backgroundColor = [currentTheme backgroundColor];
    self.composeSeparatorView.backgroundColor = [currentTheme tableViewSeparatorColor];
}

 #pragma mark - Navigation

 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
     if ([segue.identifier isEqualToString:@"PushToPreview"]) {
         NSString *messageText = [self.composeTextTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

         if (self.type == kMCLComposeTypeThread || self.type == kMCLComposeTypeReply) {
             BOOL signatureEnabled = [self.bag.settings isSettingActivated:MCLSettingSignatureEnabled orDefault:YES];
             if (signatureEnabled) {
                 NSString *signature = [self.bag.settings objectForSetting:MCLSettingSignatureText
                                                                 orDefault:kSettingsSignatureTextDefault];
                 messageText = [messageText stringByAppendingString:@"\n\n"];
                 messageText = [messageText stringByAppendingString:signature];
             }
         }

         MCLComposeMessagePreviewViewController *composeMessagePreviewVC = segue.destinationViewController;
         [composeMessagePreviewVC setBag:self.bag];
         [composeMessagePreviewVC setDelegate:self.delegate];
         [composeMessagePreviewVC setType:self.type];
         [composeMessagePreviewVC setBoardId:self.boardId];
         [composeMessagePreviewVC setThreadId:self.threadId];
         [composeMessagePreviewVC setMessageId:self.messageId];
         [composeMessagePreviewVC setSubject:self.composeSubjectTextField.text];
         [composeMessagePreviewVC setText:messageText];
     }
 }

@end
