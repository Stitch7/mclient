//
//  MCLMessageList2FrameStyleViewController.h
//  mclient
//
//  Created by Christopher Reitz on 16.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCLBoard;
@class MCLThread;

@interface MCLMessageList2FrameStyleViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate, AVSpeechSynthesizerDelegate, UISplitViewControllerDelegate>

@property (strong, nonatomic) MCLBoard *board;
@property (strong, nonatomic) MCLThread *thread;

@end
