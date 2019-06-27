//
//  MCLMessageListLoadingViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoadingViewController.h"

@protocol MCLDependencyBag;
@class MCLThread;

@interface MCLMessageListLoadingViewController : MCLLoadingViewController

- (void)loadThread:(MCLThread *)thread;

@end
