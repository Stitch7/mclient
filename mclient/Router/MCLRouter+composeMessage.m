//
//  MCLRouter+composeMessage.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRouter+composeMessage.h"

#import "MCLDependencyBag.h"
#import "MCLBoard.h"
#import "MCLMessage.h"
#import "MCLThread.h"
#import "MCLEditTextRequest.h"
#import "MCLPreviewMessageRequest.h"
#import "MCLModalNavigationController.h"
#import "MCLLoadingViewController.h"
#import "MCLComposeMessageViewController.h"
#import "MCLComposeMessagePreviewViewController.h"


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

    MCLEditTextRequest *request = [[MCLEditTextRequest alloc] initWithClient:self.bag.httpClient message:message];
    [request loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        editMessageVC.message.text = [[data firstObject] objectForKey:@"editText"];
        [self.masterNavigationController presentViewController:self.modalNavigationController animated:YES completion:nil];
    }];

    return editMessageVC;
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

@end
