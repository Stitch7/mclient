//
//  MCLRouter+openURL.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRouter.h"

@class MCLMessageListViewController;

@interface MCLRouter (openURL)

- (MCLMessageListViewController *)pushToURL:(NSURL *)destinationURL;

@end
