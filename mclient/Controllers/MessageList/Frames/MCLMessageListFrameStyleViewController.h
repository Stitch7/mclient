//
//  MCLMessageListFrameStyleViewController.h
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@import AVFoundation;
@import WebKit;

#import "MCLMessageListViewController.h"
#import "MCLProfileTableViewController.h"
#import "MCLComposeMessageViewController.h"

@class MCLMessageToolbar;

@interface MCLMessageListFrameStyleViewController : MCLMessageListViewController <MCLProfileTableViewControllerDelegate, MCLComposeMessageViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, WKNavigationDelegate, AVSpeechSynthesizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *topFrame;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topFrameHeightConstraint;
@property (weak, nonatomic) IBOutlet MCLMessageToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIView *bottomFrame;

@end
