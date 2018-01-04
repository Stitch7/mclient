//
//  MCLRouter+openURL.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@import SafariServices;

#import "MCLDependencyBag.h"
#import "MCLRouter+openURL.h"
#import "MCLRouter+mainNavigation.h"
#import "MCLThreadIdForMessageRequest.h"
#import "MCLSettings.h"
#import "MCLTheme.h"
#import "MCLMessage.h"
#import "MCLThread.h"
#import "MCLBoard.h"

@implementation MCLRouter (openURL)

- (MCLMessageListViewController *)pushToURL:(NSURL *)destinationURL
{
    MCLMessageListViewController *messageListViewController = nil;
    if ([self isManiacURL:destinationURL]) {
        messageListViewController = [self pushToMessageFromUrl:destinationURL];
    } else {
        [self openLink:destinationURL];
    }

    return messageListViewController;
}

- (BOOL)isManiacURL:(NSURL *)url
{
    return [url.host hasSuffix:@"maniac-forum.de"];
}
 
- (SFSafariViewController *)openLink:(NSURL *)url
{
    if ([self.bag.settings isSettingActivated:MCLSettingOpenLinksInSafari]) {
        [UIApplication.sharedApplication openURL:url];
        return nil;
    }

    SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url];
    safariVC.preferredBarTintColor = [self.currentTheme navigationBarBackgroundColor];
    safariVC.preferredControlTintColor = [self.currentTheme tintColor];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:safariVC];
    [navigationController setNavigationBarHidden:YES animated:NO];
    [self.masterNavigationController presentViewController:navigationController animated:YES completion:nil];

    return safariVC;
}

- (MCLMessageListViewController *)pushToMessageFromUrl:(NSURL *)url
{
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSArray *queryItems = urlComponents.queryItems;
    NSString *boardId = [self valueForKey:@"brdid" fromQueryItems:queryItems];
    NSString *messageId = [self valueForKey:@"msgid" fromQueryItems:queryItems];

    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;

    MCLBoard *board = [[MCLBoard alloc] init];
    MCLThread *thread = [[MCLThread alloc] init];
    MCLMessage *message = [[MCLMessage alloc] init];
    message.messageId = [numberFormatter numberFromString:messageId];
    board.boardId = [numberFormatter numberFromString:boardId];
    thread.boardId = board.boardId;
    message.boardId = board.boardId;
    thread.board = board;
    message.board = board;
    message.thread = thread;

    MCLThreadIdForMessageRequest *request = [[MCLThreadIdForMessageRequest alloc] initWithClient:self.bag.httpClient
                                                                                         message:message];
    [request loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        if (error || data == nil) {
            NSLog(@"MCLThreadIdForMessageRequest Error: %@", error.description);
            [self openLink:url];
        } else {
            message.thread.threadId = [data firstObject];
            if ([data count] > 1) { // TODO: - hmpf
                message.thread.subject = [data lastObject];
            } else {
                message.thread.subject = [url absoluteString];
            }
            [self pushToMessage:message];
        }
    }];

    return nil; // TODO: - how we deal with that?
}

// TODO: Ugly here, at least namimg...
- (NSString *)valueForKey:(NSString *)key fromQueryItems:(NSArray *)queryItems
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", key];
    NSURLQueryItem *queryItem = [[queryItems filteredArrayUsingPredicate:predicate] firstObject];

    return queryItem.value;
}

@end
