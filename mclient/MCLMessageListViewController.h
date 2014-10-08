//
//  MCLDetailViewController.h
//  mclient
//
//  Created by Christopher Reitz on 19.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SplitViewButtonHandler.h"

@class MCLBoard;
@class MCLThread;

@interface MCLMessageListViewController : UIViewController <SplitViewButtonHandler>

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

+ (NSString *)messageHtmlSkeletonForHtml:(NSString *)html withTopMargin:(int)topMargin;
- (void)loadThread:(MCLThread *)inThread fromBoard:(MCLBoard *)inBoard;

@end
