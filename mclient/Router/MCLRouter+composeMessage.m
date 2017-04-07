//
//  MCLRouter+composeMessage.m
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRouter+composeMessage.h"

#import "MCLBoard.h"
#import "MCLMessage.h"
#import "MCLThread.h"
#import "MCLModalNavigationController.h"
#import "MCLComposeMessageViewController.h"
#import "MCLComposeMessagePreviewViewController.h"

@implementation MCLRouter (composeMessage)

- (MCLComposeMessageViewController *)modalToComposeThreadToBoard:(MCLBoard *)board
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ComposeMessage" bundle:nil];
    MCLComposeMessageViewController *composeThreadVC = [storyboard instantiateViewControllerWithIdentifier:@"MCLComposeMessageViewController"];
    composeThreadVC.bag = self.bag;
    composeThreadVC.boardId = board.boardId;
    composeThreadVC.type = kMCLComposeTypeThread;
//    composeThreadVC.delegate = delegate;

    MCLModalNavigationController *navigationVC = [[MCLModalNavigationController alloc] initWithRootViewController:composeThreadVC];
    [self.masterNavigationController presentViewController:navigationVC animated:YES completion:nil];

    return composeThreadVC;
}

- (MCLComposeMessageViewController *)modalToComposeReplyToMessage:(MCLMessage *)message
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ComposeMessage" bundle:nil];
    MCLComposeMessageViewController *replyToMessageVC = [storyboard instantiateViewControllerWithIdentifier:@"MCLComposeMessageViewController"];
    replyToMessageVC.bag = self.bag;
    replyToMessageVC.messageId = message.messageId;
    replyToMessageVC.threadId = message.thread.threadId;
    replyToMessageVC.boardId = message.board.boardId;
    replyToMessageVC.type = kMCLComposeTypeReply;
//    composeThreadVC.delegate = delegate;

    NSString *subject = message.subject;
    NSString *subjectReplyPrefix = @"Re:";
    if ([subject length] < 3 || ![[subject substringToIndex:3] isEqualToString:subjectReplyPrefix]) {
        subject = [subjectReplyPrefix stringByAppendingString:subject];
    }
    replyToMessageVC.subject = subject;

    MCLModalNavigationController *navigationVC = [[MCLModalNavigationController alloc] initWithRootViewController:replyToMessageVC];
    [self.masterNavigationController presentViewController:navigationVC animated:YES completion:nil];

    return replyToMessageVC;
}

- (MCLComposeMessageViewController *)modalToEditMessage:(MCLMessage *)message
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ComposeMessage" bundle:nil];
    MCLComposeMessageViewController *editMessageVC = [storyboard instantiateViewControllerWithIdentifier:@"MCLComposeMessageViewController"];
    editMessageVC.bag = self.bag;
    editMessageVC.messageId = message.messageId;
    editMessageVC.threadId = message.thread.threadId;
    editMessageVC.boardId = message.board.boardId;
    editMessageVC.type = kMCLComposeTypeEdit;
    editMessageVC.subject = message.subject;
    editMessageVC.text = message.text;
//    composeThreadVC.delegate = delegate;

    MCLModalNavigationController *navigationVC = [[MCLModalNavigationController alloc] initWithRootViewController:editMessageVC];
    [self.masterNavigationController presentViewController:navigationVC animated:YES completion:nil];

    return editMessageVC;
}

- (MCLComposeMessagePreviewViewController *)pushToPreviewForMessage:(MCLMessage *)message
{
//    MCLComposeMessagePreviewViewController

    return nil;
}

@end
