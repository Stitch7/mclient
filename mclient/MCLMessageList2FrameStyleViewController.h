//
//  MCLMessageList2FrameStyleViewController.h
//  mclient
//
//  Created by Christopher Reitz on 16.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "MCLDetailViewController.h"
#import "MCLComposeMessageViewController.h"

@class MCLBoard;
@class MCLThread;

@interface MCLMessageList2FrameStyleViewController : MCLDetailViewController <UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate, AVSpeechSynthesizerDelegate, MCLComposeMessageViewControllerDelegate>

@property (strong, nonatomic) MCLBoard *board;
@property (strong, nonatomic) MCLThread *thread;

@end
