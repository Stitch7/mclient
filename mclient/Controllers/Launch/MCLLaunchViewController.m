//
//  MCLLaunchViewController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLaunchViewController.h"

#import "MCLDependencyBag.h"
#import "MCLDefaultTheme.h"
#import "UIView+addConstraints.h"
#import "MCLPacmanLoadingView.h"


@implementation MCLLaunchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.logoLabel.textColor = [UIColor lightGrayColor];
    [self configurePacmanView];
}

- (void)configurePacmanView
{
    MCLPacmanLoadingView *loadingView = [[MCLPacmanLoadingView alloc] initWithTheme:[[MCLDefaultTheme alloc] init]];
    loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loadingContainerView insertSubview:loadingView atIndex:0];
    [loadingView constrainEdgesTo:self.loadingContainerView];
    [self.loadingContainerView bringSubviewToFront:loadingView];
}

@end
