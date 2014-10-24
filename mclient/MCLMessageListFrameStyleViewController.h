//
//  MCLMessageList2FrameStyleViewController.h
//  mclient
//
//  Created by Christopher Reitz on 16.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "MCLMessageListViewController.h"
#import "MCLProfileTableViewController.h"
#import "MCLComposeMessageViewController.h"

@interface MCLMessageListFrameStyleViewController : MCLMessageListViewController <MCLProfileTableViewControllerDelegate, MCLComposeMessageViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate, AVSpeechSynthesizerDelegate>

@end
