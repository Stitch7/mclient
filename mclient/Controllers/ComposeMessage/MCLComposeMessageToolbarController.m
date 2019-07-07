//
//  MCLComposeMessageToolbarController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLComposeMessageToolbarController.h"

@import AVFoundation;

#import <ImgurSession.h>
#import <MRProgressOverlayView.h>

#import "UIViewController+Additions.h"
#import "MCLDependencyBag.h"
#import "MCLRouter+composeMessage.h"
#import "MCLComposeMessageViewController.h"
#import "MCLMessage.h"
#import "MCLQuote.h"
#import "MCLQuoteMessageRequest.h"
#import "MCLMessageTextView.h"


@interface MCLComposeMessageToolbarController () <SwiftyGiphyHelperDelegate>

@property (weak, nonatomic) MCLComposeMessageViewController *parentViewController;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) MRProgressOverlayView *progressView;
@property (strong, nonatomic) SwiftyGiphyHelper *giphyHelper;

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

    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"camera_action_choose_title", nil)
                                                                         message:nil
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

    [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"camera_action_giphy", nil)
                                                    style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                        [self showGiphy:sender];
                                                    }]];

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
    } else if (authStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera fromButton:sender];
            }
        }];
    } else {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera fromButton:sender];
    }
}

- (void)showPhotoPicker:(id)sender
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary fromButton:sender];
}

- (void)showGiphy:(id)sender
{
    self.giphyHelper = [self.parentViewController.bag.router modalToGiphy];
    self.giphyHelper.delegate = self;
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType fromButton:(UIBarButtonItem *)button
{
    UIImagePickerController *imagePickerController = [self.parentViewController.bag.router modalToImagePickerForSourceType:sourceType fromButton:button];
    imagePickerController.delegate = self;
    self.imagePickerController = imagePickerController;
}

- (void)messageTextViewToolbar:(MCLMessageTextViewToolbar *)toolbar quoteButtonPressed:(UIBarButtonItem *)sender
{
    [sender setEnabled:NO];

    MCLQuoteMessageRequest *request = [[MCLQuoteMessageRequest alloc] initWithClient:self.parentViewController.bag.httpClient
                                                                             message:self.parentViewController.message];
    [request loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        if (error) {
            [self.parentViewController presentError:error];
        } else {
            MCLQuote *quote = [data firstObject];
            if ([quote hasBlocks]) {
                [self presentPickerActionSheetForQuote:quote];
            } else {
                [quote appendToTextField:self.parentViewController.textView];
            }
        }
        [sender setEnabled:YES];
    }];
}

- (void)presentPickerActionSheetForQuote:(MCLQuote *)quote
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select quote", nil)
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    for (NSString *block in quote.blocks) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:[block substringFromIndex:1]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           NSString *textViewContent = self.parentViewController.textView.text;
                                                           if (textViewContent.length > 0) {
                                                               textViewContent = [textViewContent stringByAppendingString:@"\n\n"];
                                                           }
                                                           self.parentViewController.textView.text = [[textViewContent stringByAppendingString:block] stringByAppendingString:@"\n"];
                                                       }];
        [alert addAction:action];
    }

    UIAlertAction *fullQuoteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Full quote", nil)
                                                              style:UIAlertActionStyleDestructive
                                                            handler:^(UIAlertAction * action) {
                                                                NSString *textViewContent = [@"\n\n" stringByAppendingString:self.parentViewController.textView.text];
                                                                self.parentViewController.textView.text = [quote.string stringByAppendingString:textViewContent];
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

    self.parentViewController.bag.application.networkActivityIndicatorVisible = YES;

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

- (void)dissmissProgressViewWithSuccess:(BOOL)success completionHandler:(void (^)(void))completion
{
    self.parentViewController.bag.application.networkActivityIndicatorVisible = NO;

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
            [self configureProgressView];
            if (success) {
                [self.parentViewController.textView becomeFirstResponder];
            }
        }];
    } afterDelay:0.5];
}

- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay
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

#pragma mark - SwiftyGiphyHelperDelegate

- (void)giphyControllerDidCancel
{
    [self.parentViewController.bag.router dismissModalWithCompletion:^{
        [self.parentViewController.textView becomeFirstResponder];
    }];
}

- (void)giphyControllerDidSelectGifWithUrl:(NSURL * _Nonnull)url
{
    [self.parentViewController.bag.router dismissModalWithCompletion:^{
        [self.parentViewController.textView addImage:url];
        [self.parentViewController.textView becomeFirstResponder];
    }];
}

@end
