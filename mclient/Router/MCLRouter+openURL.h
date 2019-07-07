//
//  MCLRouter+openURL.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRouter.h"

@class MCLMessageListViewController;
@class SFSafariViewController;

@interface MCLRouter (openURL)

- (MCLMessageListViewController *)pushToURL:(NSURL *)destinationURL;
- (MCLMessageListViewController *)pushToURL:(NSURL *)destinationURL fromPresentingViewController:(UIViewController *)presentingViewController;
- (SFSafariViewController *)openRawManiacForumURL:(NSURL *)destinationURL fromPresentingViewController:(UIViewController *)presentingViewController;
- (void)openLinkInSafari:(NSURL *)url;

@end
