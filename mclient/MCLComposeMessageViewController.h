//
//  MCLComposeMessageTableViewController.h
//  mclient
//
//  Created by Christopher Reitz on 31.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MCLComposeMessageViewControllerDelegate;

@interface MCLComposeMessageViewController : UIViewController <UITextFieldDelegate>

@property (weak) id<MCLComposeMessageViewControllerDelegate> delegate;

@property (assign) NSUInteger type;
@property (strong, nonatomic) NSNumber *boardId;
@property (strong, nonatomic) NSNumber *messageId;
@property (strong, nonatomic) NSString *subject;
@property (strong, nonatomic) NSString *text;

@end

@protocol MCLComposeMessageViewControllerDelegate <NSObject>

@required
- (void)messageSentWithType:(NSUInteger)type;

@optional
- (void)handleRotationChangeInBackground;

@end
