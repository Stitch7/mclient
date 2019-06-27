//
//  MCLLaunchViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLaunchViewController.h"

#import "MCLLightTheme.h"
#import "UIView+addConstraints.h"
#import "MCLPacmanLoadingView.h"


NSInteger const MCLLaunchViewLogoLabelTag = 1;
NSInteger const MCLLaunchViewLoadingContainerViewTag = 2;

@interface MCLLaunchViewController ()

@property (strong, nonatomic) UIViewController *launchViewController;
@property (strong, nonatomic) UILabel *logoLabel;

@end

@implementation MCLLaunchViewController

#pragma mark - Initializers

- (instancetype)initWithLaunchViewController:(UIViewController *)launchViewController
{
    self = [super init];
    if (!self) return nil;

    self.launchViewController = launchViewController;

    [self initSubviews];

    return self;
}

- (void)initSubviews
{
    self.logoLabel = [self.launchViewController.view viewWithTag:MCLLaunchViewLogoLabelTag];
    self.loadingContainerView = [self.launchViewController.view viewWithTag:MCLLaunchViewLoadingContainerViewTag];
    [self addChildViewController:self.launchViewController];
    [self.view addSubview:self.launchViewController.view];
    [self.view bringSubviewToFront:self.launchViewController.view];
}

#pragma mark - ViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.logoLabel.textColor = [UIColor lightGrayColor];
    [self configurePacmanView];
}

- (void)configurePacmanView
{
    MCLPacmanLoadingView *loadingView = [[MCLPacmanLoadingView alloc] initWithTheme:[[MCLLightTheme alloc] init]];
    loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loadingContainerView insertSubview:loadingView atIndex:0];
    [loadingView constrainEdgesTo:self.loadingContainerView];
    [self.loadingContainerView bringSubviewToFront:loadingView];
    self.loadingContainerView.hidden = NO;
}

@end
