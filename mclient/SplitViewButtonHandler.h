//
//  SplitViewButtonHandler.h
//  DetailViewSwitch
//
//  Created by Tim Harris on 1/17/14.
//  Copyright (c) 2014 Tim Harris. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SplitViewButtonHandler <NSObject>

@property (nonatomic, strong) UIBarButtonItem *splitViewButton;

-(void)setSplitViewButton:(UIBarButtonItem *)splitViewButton forPopoverController:(UIPopoverController *)popoverController;

@end
