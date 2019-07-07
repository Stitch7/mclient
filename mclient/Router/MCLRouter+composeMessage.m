//
//  MCLRouter+composeMessage.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRouter+composeMessage.h"

#import "MCLDependencyBag.h"
#import "MCLThemeManager.h"
#import "MCLBoard.h"
#import "MCLMessage.h"
#import "MCLDraft.h"
#import "MCLThread.h"
#import "MCLPreviewMessageRequest.h"
#import "MCLModalNavigationController.h"
#import "MCLLoadingViewController.h"
#import "MCLComposeMessageViewController.h"
#import "MCLComposeMessagePreviewViewController.h"
#import "MCLDraftTableViewController.h"


@implementation MCLRouter (composeMessage)

- (MCLComposeMessageViewController *)modalToComposeThreadToBoard:(MCLBoard *)board
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ComposeMessage" bundle:nil];
    MCLComposeMessageViewController *composeThreadVC = [storyboard instantiateViewControllerWithIdentifier:@"MCLComposeMessageViewController"];
    composeThreadVC.bag = self.bag;
    composeThreadVC.message = [MCLMessage messageNewWithBoard:board];

    self.modalNavigationController = [[MCLModalNavigationController alloc] initWithRootViewController:composeThreadVC];
    [self.masterNavigationController presentViewController:self.modalNavigationController animated:YES completion:nil];

    return composeThreadVC;
}

- (MCLComposeMessageViewController *)modalToComposeReplyToMessage:(MCLMessage *)message
{
    message.type = kMCLComposeTypeReply;

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ComposeMessage" bundle:nil];
    MCLComposeMessageViewController *replyToMessageVC = [storyboard instantiateViewControllerWithIdentifier:@"MCLComposeMessageViewController"];
    replyToMessageVC.bag = self.bag;

    NSString *subject = message.subject;
    NSString *subjectReplyPrefix = @"Re:";
    if ([subject length] < 3 || ![[subject substringToIndex:3] isEqualToString:subjectReplyPrefix]) {
        subject = [subjectReplyPrefix stringByAppendingString:subject];
    }
    message.subject = subject;

    replyToMessageVC.message = message;

    self.modalNavigationController = [[MCLModalNavigationController alloc] initWithRootViewController:replyToMessageVC];
    [self.masterNavigationController presentViewController:self.modalNavigationController animated:YES completion:nil];

    return replyToMessageVC;
}

- (MCLComposeMessageViewController *)modalToEditMessage:(MCLMessage *)message
{
    message.type = kMCLComposeTypeEdit;

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ComposeMessage" bundle:nil];
    MCLComposeMessageViewController *editMessageVC = [storyboard instantiateViewControllerWithIdentifier:@"MCLComposeMessageViewController"];
    editMessageVC.bag = self.bag;
    editMessageVC.message = message;
    self.modalNavigationController = [[MCLModalNavigationController alloc] initWithRootViewController:editMessageVC];

    [self.masterNavigationController presentViewController:self.modalNavigationController animated:YES completion:nil];

    return editMessageVC;
}

- (MCLComposeMessageViewController *)modalToEditDraft:(MCLDraft *)draft
{
    MCLMessage *message = [MCLMessage messageFromDraft:draft];
    MCLComposeMessageViewController *composeMessageVC;
    if (draft.type == kMCLComposeTypeThread) {
        composeMessageVC = [self.bag.router modalToComposeThreadToBoard:message.board];
    } else {
        composeMessageVC = [self.bag.router modalToComposeReplyToMessage:message];
    }

    return composeMessageVC;
}

- (MCLComposeMessagePreviewViewController *)pushToPreviewForMessage:(MCLMessage *)message
{
    MCLPreviewMessageRequest *previewMessageRequest = [[MCLPreviewMessageRequest alloc] initWithClient:self.bag.httpClient message:message];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ComposeMessage" bundle:nil];
    MCLComposeMessagePreviewViewController *previewMessageVC = [storyboard instantiateViewControllerWithIdentifier:@"MCLComposeMessagePreviewViewController"];
    previewMessageVC.bag = self.bag;
    previewMessageVC.message = message;

    MCLLoadingViewController *loadingVC = [[MCLLoadingViewController alloc] initWithBag:self.bag
                                                                                request:previewMessageRequest
                                                                  contentViewController:previewMessageVC];

    [self.modalNavigationController pushViewController:loadingVC animated:YES];

    return previewMessageVC;
}

- (MCLDraftTableViewController *)pushToDrafts
{

    MCLDraftTableViewController *draftsVC = [[MCLDraftTableViewController alloc] initWithBag:self.bag];
    [self.masterNavigationController pushViewController:draftsVC animated:YES];

    return draftsVC;
}

- (UIImagePickerController *)modalToImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType fromButton:(UIBarButtonItem *)button
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.modalPresentationStyle =
        (sourceType == UIImagePickerControllerSourceTypeCamera) ? UIModalPresentationFullScreen : UIModalPresentationPopover;

    UIPopoverPresentationController *presentationController = imagePickerController.popoverPresentationController;
    presentationController.barButtonItem = button;
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;

    [self.modalNavigationController presentViewController:imagePickerController animated:YES completion:nil];

    return imagePickerController;
}

- (SwiftyGiphyHelper *)modalToGiphy
{
    SwiftyGiphyHelper *giphyHelper = [[SwiftyGiphyHelper alloc] initWithApiKey:GIPHY_KEY];
    UIViewController *giphyVC = [giphyHelper makeGiphyViewControllerWithTheme:self.bag.themeManager.currentTheme];

    UINavigationController *giphyNavController = [[UINavigationController alloc] initWithRootViewController:giphyVC];
    [self.modalNavigationController presentViewController:giphyNavController animated:YES completion:nil];

    return giphyHelper;
}

- (void)dismissModalWithCompletion: (void (^)(void))completion
{
    [self.modalNavigationController dismissViewControllerAnimated:YES completion:completion];
}

@end
