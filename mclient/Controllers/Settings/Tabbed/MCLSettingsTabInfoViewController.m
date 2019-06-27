//
//  MCLSettingsTabInfoViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSettingsTabInfoViewController.h"

@interface MCLSettingsTabInfoViewController ()

@end

@implementation MCLSettingsTabInfoViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.tabBarController setTitle:@"About this App"];
}

@end
