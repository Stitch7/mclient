//
//  MCLComposeMessageTableViewController.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageTextView.h"
#import "MCLMessageTextViewToolbarDelegate.h"

@protocol MCLDependencyBag;
@protocol MCLComposeMessageViewControllerDelegate;

@interface MCLComposeMessageViewController : UIViewController <MCLMessageTextViewErrorHandler, MCLMessageTextViewToolbarDelegate, UITextFieldDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (weak) id<MCLComposeMessageViewControllerDelegate> delegate;
@property (assign) NSUInteger type;
@property (strong, nonatomic) NSNumber *boardId;
@property (strong, nonatomic) NSNumber *threadId;
@property (strong, nonatomic) NSNumber *messageId;
@property (strong, nonatomic) NSString *subject;
@property (strong, nonatomic) NSString *text;

@end
