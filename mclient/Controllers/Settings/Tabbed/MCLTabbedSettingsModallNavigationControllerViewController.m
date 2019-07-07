//
//  MCLTabbedSettingsModallNavigationControllerViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLTabbedSettingsModallNavigationControllerViewController.h"

@interface MCLTabbedSettingsModallNavigationControllerViewController ()

@end

@implementation MCLTabbedSettingsModallNavigationControllerViewController

#pragma mark - Actions

- (void)downButtonPressed:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
