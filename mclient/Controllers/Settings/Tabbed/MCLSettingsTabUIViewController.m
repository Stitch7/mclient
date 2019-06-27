//
//  MCLSettingsTabUIViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSettingsTabUIViewController.h"

@interface MCLSettingsTabUIViewController ()

@end

@implementation MCLSettingsTabUIViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.tabBarController setTitle:@"UI Settings"];
}

@end
