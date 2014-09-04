//
//  MCLComposeMessageTableViewController.h
//  mclient
//
//  Created by Christopher Reitz on 31.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

// typedef NS_ENUM(NSUInteger, kComposeType) {
typedef enum kComposeType : NSUInteger {
    kComposeTypeThread,
    kComposeTypeReply,
    kComposeTypeEdit
  
} kComposeType;

@interface MCLComposeMessageTableViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate>

@property (assign) NSUInteger type;
@property (strong, nonatomic) NSNumber *boardId;
@property (strong, nonatomic) NSNumber *messageId;
@property (strong, nonatomic) NSString *subject;
@property (strong, nonatomic) NSString *text;

@end
