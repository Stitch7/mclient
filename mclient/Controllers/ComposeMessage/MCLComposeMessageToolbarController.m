//
//  MCLComposeMessageToolbarController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLComposeMessageToolbarController.h"

@import AVFoundation;

#import "ImgurSession.h"
#import "MRProgressOverlayView.h"

#import "UIViewController+Additions.h"
#import "MCLDependencyBag.h"
#import "MCLComposeMessageViewController.h"
#import "MCLMessage.h"
#import "MCLQuoteMessageRequest.h"
#import "MCLMessageTextView.h"


@interface MCLComposeMessageToolbarController ()

@property (weak, nonatomic) MCLComposeMessageViewController *parentViewController;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) MRProgressOverlayView *progressView;

@end

@implementation MCLComposeMessageToolbarController

#pragma mark - Initializers

- (instancetype)initWithParentViewController:(MCLComposeMessageViewController *)parentViewController
{
    self = [super init];
    if (!self) return nil;

    self.parentViewController = parentViewController;

    [self configureProgressView];

    return self;
}

#pragma mark - Configuration

- (void)configureProgressView
{
    self.progressView = [MRProgressOverlayView new];
    self.progressView.mode = MRProgressOverlayViewModeDeterminateCircular;
    self.progressView.titleLabelText = NSLocalizedString(@"Uploading", nil);
    [self.parentViewController.view addSubview:self.progressView];
}

#pragma mark - MCLMessageTextViewToolbarDelegate

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar boldButtonPressed:(UIBarButtonItem *)sender
{
    [self.parentViewController.textView formatBold];
}

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar italicButtonPressed:(UIBarButtonItem *)sender
{
    [self.parentViewController.textView formatItalic];
}

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar underlineButtonPressed:(UIBarButtonItem *)sender
{
    [self.parentViewController.textView formatUnderline];
}

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar strikestroughButtonPressed:(UIBarButtonItem *)sender
{
    [self.parentViewController.textView formatStroke];
}

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar spoilerButtonPressed:(UIBarButtonItem *)sender
{
    [self.parentViewController.textView formatSpoiler];
}

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar cameraButtonPressed:(UIBarButtonItem *)sender;
{
    [self.parentViewController.textView resignFirstResponder];

    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil
                                                                         message:nil // TODO: @"Bild hinzufügen" -> ???
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];

    [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                    style:UIAlertActionStyleCancel
                                                  handler:^(UIAlertAction *action) {
                                                      [self.parentViewController.textView becomeFirstResponder];
                                                  }]];

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"camera_action_take_photo", nil)
                                                        style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                            [self showCamera:sender];
                                                        }]];
    }

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"camera_action_choose_album", nil)
                                                        style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                            [self showPhotoPicker:sender];
                                                        }]];
    }

    [self.parentViewController presentViewController:actionSheet animated:YES completion:nil];
}

- (void)showCamera:(id)sender
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusDenied) {
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:NSLocalizedString(@"camera_access_error_title", nil)
                                            message:NSLocalizedString(@"camera_access_error_message", nil)
                                     preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];

        [self.parentViewController presentViewController:alertController animated:YES completion:nil];
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

    [self.parentViewController presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar quoteButtonPressed:(UIBarButtonItem *)sender
{
    [sender setEnabled:NO];

    MCLMessage *message = [[MCLMessage alloc] init];
    message.boardId = self.parentViewController.message.boardId;
    message.messageId = self.parentViewController.message.messageId;

    MCLQuoteMessageRequest *request = [[MCLQuoteMessageRequest alloc] initWithClient:self.parentViewController.bag.httpClient
                                                                             message:message];
    [request loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        if (error) {
            [self.parentViewController presentError:error];
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
                NSString *textViewContent = [@"\n\n" stringByAppendingString:self.parentViewController.textView.text];
                self.parentViewController.textView.text = [quoteString stringByAppendingString:textViewContent];
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
                                                           NSString *textViewContent = self.parentViewController.textView.text;
                                                           if (textViewContent.length > 0) {
                                                               textViewContent = [textViewContent stringByAppendingString:@"\n\n"];
                                                           }
                                                           self.parentViewController.textView.text = [[textViewContent stringByAppendingString:quoteBlock] stringByAppendingString:@"\n"];
                                                       }];
        [alert addAction:action];
    }

    UIAlertAction *fullQuoteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Full quote", nil)
                                                              style:UIAlertActionStyleDestructive
                                                            handler:^(UIAlertAction * action) {
                                                                NSString *textViewContent = [@"\n\n" stringByAppendingString:self.parentViewController.textView.text];
                                                                self.parentViewController.textView.text = [quoteString stringByAppendingString:textViewContent];
                                                            }];
    [alert addAction:fullQuoteAction];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:cancelAction];

    [self.parentViewController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.7f);

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [IMGImageRequest uploadImageWithData:imageData
                                   title:self.parentViewController.message.subject
                                progress:^(NSProgress *progress) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [self.progressView setProgress:(float)progress.fractionCompleted animated:YES];
                                    });
                                }
                                 success:^(IMGImage *image) {
                                     [self dissmissProgressViewWithSuccess:YES completionHandler:^{
                                         [self.parentViewController.textView addImage:image.url];
                                     }];
                                 }
                                 failure:^(NSURLSessionDataTask *task, NSError *error) {
                                     [self dissmissProgressViewWithSuccess:YES completionHandler:^{
                                         NSLog(@"Imgur upload error: %@", error);
                                         [self.parentViewController.view endEditing:YES];
                                         [self.parentViewController presentError:error];
                                     }];
                                 }];
    self.imagePickerController = nil;

    [self.parentViewController dismissViewControllerAnimated:YES completion:^{
        [self.progressView show:YES];
    }];
}

- (void)dissmissProgressViewWithSuccess:(BOOL)success completionHandler:(void(^)(void))completion
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if (success) {
        self.progressView.mode = MRProgressOverlayViewModeCheckmark;
        self.progressView.titleLabelText = NSLocalizedString(@"image_upload_succeed", nil);
    } else {
        self.progressView.mode = MRProgressOverlayViewModeCross;
        self.progressView.titleLabelText = NSLocalizedString(@"image_upload_failed", nil);
    }

    completion();

    [self performBlock:^{
        [self.progressView dismiss:YES completion:^{
            self.progressView.mode = MRProgressOverlayViewModeDeterminateCircular;
            self.progressView.titleLabelText = NSLocalizedString(@"Uploading", nil);
            self.progressView.progress = 0;

            if (success) {
                [self.parentViewController.textView becomeFirstResponder];
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

    [self.parentViewController dismissViewControllerAnimated:YES completion:^{
        [self.parentViewController.textView becomeFirstResponder];
    }];
}

@end
