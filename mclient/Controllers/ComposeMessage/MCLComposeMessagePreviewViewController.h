//
//  MCLPreviewMessageViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoadingViewControllerDelegate.h"

@protocol MCLDependencyBag;
@protocol MCLComposeMessageViewControllerDelegate;

@class MCLMessage;

@interface MCLComposeMessagePreviewViewController : UIViewController <UIWebViewDelegate, MCLLoadingViewControllerDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (weak) id<MCLComposeMessageViewControllerDelegate> delegate;
@property (strong, nonatomic) MCLMessage *message;

@end
