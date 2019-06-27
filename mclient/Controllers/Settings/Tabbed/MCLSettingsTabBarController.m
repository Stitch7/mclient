//
//  MCLSettingsTabBarController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSettingsTabBarController.h"

@interface MCLSettingsTabBarController ()

@end

@implementation MCLSettingsTabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"downButton"]
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(downButtonPressed:)];

    for (UITabBarItem * tabBarItem in self.tabBar.items) {
        tabBarItem.title = nil;
        tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
//        tabBarItem.selectedImage = [UIImage imageNamed:@"settingtab-login-filled"];
    }
}

#pragma mark - Actions

- (void)downButtonPressed:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
