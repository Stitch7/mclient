//
//  MCLDetailViewController.m
//  mclient
//
//  Created by Christopher Reitz on 19.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLDetailViewController.h"
#import "MCLThread.h"
#import "MCLBoard.h"

@implementation MCLDetailViewController

@synthesize splitViewButton = _splitViewButton;


- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadThread:(MCLThread *)inThread fromBoard:(MCLBoard *)inBoard
{
}


#pragma mark - SplitViewButtonHandler

-(void) turnSplitViewButtonOn: (UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *) popoverController
{
    NSString *activeDetailViewControllerClassName = NSStringFromClass([[[[self.splitViewController.viewControllers lastObject] viewControllers] firstObject] class]);

    NSString *barButtonTitle = @"Threads";
    if ([activeDetailViewControllerClassName isEqualToString:@"MCLDetailViewController"]) {
        barButtonTitle = @"Boards";
    }
    barButtonItem.title = barButtonTitle;
    _splitViewButton = barButtonItem;

    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

-(void)turnSplitViewButtonOff {
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    _splitViewButton = nil;
    self.masterPopoverController = nil;
    
}

-(void) setSplitViewButton:(UIBarButtonItem *)splitViewButton forPopoverController:(UIPopoverController *)popoverController {
    if (splitViewButton != _splitViewButton) {
        if (splitViewButton) {
            [self turnSplitViewButtonOn:splitViewButton forPopoverController:popoverController];
        } else {
            [self turnSplitViewButtonOff];
        }
    }
}

@end
