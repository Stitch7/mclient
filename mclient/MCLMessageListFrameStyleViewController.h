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
#import "MCLComposeMessageViewController.h"

@class MCLBoard;
@class MCLThread;

@interface MCLMessageListFrameStyleViewController : MCLMessageListViewController <MCLComposeMessageViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate, AVSpeechSynthesizerDelegate>

@property (strong, nonatomic) MCLBoard *board;
@property (strong, nonatomic) MCLThread *thread;

@end
