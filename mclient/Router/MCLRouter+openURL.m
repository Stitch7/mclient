//
//  MCLRouter+openURL.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@import SafariServices;

#import "UIApplication+Additions.h"
#import "UIViewController+Additions.h"
#import "NSURL+isValidWebURL.h"
#import "MCLDependencyBag.h"
#import "MCLRouter+openURL.h"
#import "MCLRouter+mainNavigation.h"
#import "MCLThreadIdForMessageRequest.h"
#import "MCLSettings.h"
#import "MCLThemeManager.h"
#import "MCLTheme.h"
#import "MCLMessage.h"
#import "MCLThread.h"
#import "MCLBoard.h"


@implementation MCLRouter (openURL)

- (MCLMessageListViewController *)pushToURL:(NSURL *)destinationURL
{
    return [self pushToURL:destinationURL fromPresentingViewController:self.masterNavigationController];
}

- (MCLMessageListViewController *)pushToURL:(NSURL *)destinationURL fromPresentingViewController:(UIViewController *)presentingViewController
{
    if (![destinationURL isValidWebURL]) {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"invalid_web_url", nil), destinationURL.absoluteString];
        [presentingViewController presentErrorWithMessage:message];
        return nil;
    }

    MCLMessageListViewController *messageListViewController = nil;
    if ([self isManiacURL:destinationURL]) {
        messageListViewController = [self pushToMessageFromUrl:destinationURL];
    } else {
        [self openLink:destinationURL fromPresentingViewController:presentingViewController];
    }

    return messageListViewController;
}

- (SFSafariViewController *)openRawManiacForumURL:(NSURL *)destinationURL fromPresentingViewController:(UIViewController *)presentingViewController
{
    SFSafariViewController *safariVC;
    if (@available(iOS 11.0, *)) {
        SFSafariViewControllerConfiguration *safariConfig = [[SFSafariViewControllerConfiguration alloc] init];
        safariConfig.entersReaderIfAvailable = YES;
        safariVC = [[SFSafariViewController alloc] initWithURL:destinationURL configuration:safariConfig];
    } else if (@available(iOS 10.0, *)) {
        safariVC = [[SFSafariViewController alloc] initWithURL:destinationURL entersReaderIfAvailable:YES];
        safariVC.automaticallyAdjustsScrollViewInsets = NO;
    } else { // Fallback for iOS9
        [self openLinkInSafari:destinationURL];
        return nil;
    }
    [safariVC setModalPresentationStyle:UIModalPresentationCustom];
    [safariVC setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    safariVC.preferredBarTintColor = [self.bag.themeManager.currentTheme navigationBarBackgroundColor];
    safariVC.preferredControlTintColor = [self.bag.themeManager.currentTheme tintColor];

    [presentingViewController presentViewController:safariVC animated:YES completion:nil];

    return safariVC;
}

- (BOOL)isManiacURL:(NSURL *)url
{
    return [url.host hasSuffix:@"maniac-forum.de"];
}

- (BOOL)isYoutubeURL:(NSURL *)url
{
    return [url.host hasSuffix:@"youtube.com"] || [url.host hasSuffix:@"youtube-nocookie.com"] || [url.host hasSuffix:@"youtu.be"];
}
 
- (SFSafariViewController *)openLink:(NSURL *)url fromPresentingViewController:(UIViewController *)presentingViewController
{
    if ([self.bag.settings isSettingActivated:MCLSettingOpenLinksInSafari]) {
        [self openLinkInSafari:url];
        return nil;
    }

    if ([self isYoutubeURL:url] && [self.bag.application isYoutubeAppInstalled]) {
        [self openLinkInSafari:url];
        return nil;
    }

     // Weird code, because it's not possible to mix @available with other conditions
    if (@available(iOS 10.0, *)) {
        SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url];
        safariVC.preferredBarTintColor = [self.bag.themeManager.currentTheme navigationBarBackgroundColor];
        safariVC.preferredControlTintColor = [self.bag.themeManager.currentTheme tintColor];

        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:safariVC];
        [navigationController setNavigationBarHidden:YES animated:NO];
        [presentingViewController presentViewController:navigationController animated:YES completion:nil];

        return safariVC;
    } else {
        [self openLinkInSafari:url];
        return nil;
    }
}

- (void)openLinkInSafari:(NSURL *)url
{
    [self.bag.application openURL:url];
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
            [self openLink:url fromPresentingViewController:self.masterNavigationController];
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

// TODO: Ugly here, at least naming...
- (NSString *)valueForKey:(NSString *)key fromQueryItems:(NSArray *)queryItems
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", key];
    NSURLQueryItem *queryItem = [[queryItems filteredArrayUsingPredicate:predicate] firstObject];

    return queryItem.value;
}

@end
