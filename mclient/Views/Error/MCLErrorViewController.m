//
//  MCLErrorViewController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLErrorViewController.h"

#import "UIView+addConstraints.h"

#import "MCLMServiceErrorView.h"

@interface MCLErrorViewController ()

@property (strong, nonatomic) NSError *error;
@property (strong, nonatomic) MCLMServiceErrorView *errorView;

@end

@implementation MCLErrorViewController

- (instancetype)initWithError:(NSError *)error
{
    self = [super init];
    if (!self) return nil;

    self.errorView = [[MCLMServiceErrorView alloc] initWithFrame:CGRectZero andText:[error localizedDescription]];

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

    [self.view setNeedsLayout];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    CGFloat contentViewHeight = self.errorView.contentView.frame.size.height;
    if (contentViewHeight == 0) {
        return;
    }

//    CGFloat viewHeight = self.view.frame.size.height;
    CGFloat viewHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat topPadding = 0;
    if (contentViewHeight < viewHeight) {
        CGFloat navbarHeight = self.navigationController.navigationBar.frame.size.height;
        topPadding = ((viewHeight - navbarHeight) / 2) - (contentViewHeight / 1.6);
        topPadding = topPadding > 0 ? topPadding : 0;
    }

//    NSLog(@"~~~~~~~viewWillLayoutSubviews: %f  -  %f  -  %f", viewHeight, contentViewHeight, topPadding);

    UIEdgeInsets insets = UIEdgeInsetsMake(topPadding, 0, 0, 0);
    self.errorView.scrollView.contentInset = insets;

    [UIView animateWithDuration:0.3 animations:^{
        self.errorView.alpha = 100.0;
    }];
}


@end
