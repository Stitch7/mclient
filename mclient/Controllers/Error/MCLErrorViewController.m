//
//  MCLErrorViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLErrorViewController.h"

#import "UIView+addConstraints.h"
#import "MCLDependencyBag.h"
#import "MCLFeatures.h"
#import "MCLRouter.h"
#import "MCLSoundEffectPlayer.h"
#import "MCLMServiceErrorView.h"
#import "MCLInternetConnectionErrorView.h"

@interface MCLErrorViewController ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) NSError *error;

@end

@implementation MCLErrorViewController

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag type:(NSUInteger)type error:(NSError *)error
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;
    self.errorType = type;

    if (type == kMCLErrorTypeNoInternetConnection) {
        self.errorView = [[MCLInternetConnectionErrorView alloc] init];
    } else {
        self.errorView = [[MCLMServiceErrorView alloc] initWithFrame:CGRectZero andText:[error localizedDescription]];
    }

    if (![self.bag.features isFeatureWithNameEnabled:MCLFeatureTetris]) {
        self.errorView.gameButton.enabled = NO;
        self.errorView.gameButton.hidden = YES;
    }
    [self.errorView.gameButton addTarget:self action:@selector(gameButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.errorView.translatesAutoresizingMaskIntoConstraints = NO;
    self.errorView.alpha = 0;
    [self.view addSubview:self.errorView];
    [self.errorView constrainEdgesTo:self.view];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.bag.soundEffectPlayer playErrorSound];

    [self.view setNeedsLayout];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    CGFloat contentViewHeight = self.errorView.contentView.frame.size.height;
    if (contentViewHeight == 0) {
        return;
    }

    CGFloat viewHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat topPadding = 0;
    if (contentViewHeight < viewHeight) {
        CGFloat navbarHeight = self.navigationController.navigationBar.frame.size.height;
        topPadding = ((viewHeight - navbarHeight) / 2) - (contentViewHeight / 1.6);
        topPadding = topPadding > 0 ? topPadding : 0;
    }

    UIEdgeInsets insets = UIEdgeInsetsMake(topPadding, 0, 0, 0);
    self.errorView.scrollView.contentInset = insets;

    [UIView animateWithDuration:0.3 animations:^{
        self.errorView.alpha = 100.0;
    }];
}

#pragma mark - Actions

- (void)gameButtonPressed:(UIButton *)sender
{
    (void)[self.bag.router modalToGame];
}

@end
