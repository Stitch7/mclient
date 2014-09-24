//
//  MCLComposeMessageTableViewController.h
//  mclient
//
//  Created by Christopher Reitz on 31.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MCLComposeMessageViewControllerDelegate;

typedef NS_ENUM(NSUInteger, kComposeType) {
    kComposeTypeThread,
    kComposeTypeReply,
    kComposeTypeEdit
};

@interface MCLComposeMessageViewController : UIViewController <UITextFieldDelegate>

@property (weak) id<MCLComposeMessageViewControllerDelegate> delegate;

@property (assign) NSUInteger type;
@property (strong, nonatomic) NSNumber *boardId;
@property (strong, nonatomic) NSNumber *messageId;
@property (strong, nonatomic) NSString *subject;
@property (strong, nonatomic) NSString *text;

@end

@protocol MCLComposeMessageViewControllerDelegate <NSObject>

- (void)composeMessageViewControllerDidFinish:(MCLComposeMessageViewController *)inController;

@end
