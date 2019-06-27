//
//  MCLLicenseViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLicenseViewController.h"

#import "UIView+addConstraints.h"
#import "MCLDependencyBag.h"
#import "MCLThemeManager.h"
#import "MCLTheme.h"
#import "MCLLicense.h"


@interface MCLLicenseViewController ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) MCLLicense *license;
@property (strong, nonatomic) UITextView *textView;

@end

@implementation MCLLicenseViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag andLicense:(MCLLicense *)license;
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;
    self.license = license;

    return self;
}

#pragma mark - ViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureView];
}

- (void)viewDidLayoutSubviews
{
    if (self.textView) {
        // Workaround to fix initial scroll position
        [self.textView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    }
}

#pragma mark - Configuration

- (void)configureView
{
    self.title = self.license.name;
    self.view.backgroundColor = [self.bag.themeManager.currentTheme backgroundColor];

    self.textView = [[UITextView alloc] init];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.textColor = [self.bag.themeManager.currentTheme textColor];
    self.textView.editable = NO;
    self.textView.font = [UIFont systemFontOfSize:16];
    self.textView.dataDetectorTypes = UIDataDetectorTypeLink;
    self.textView.contentInset = UIEdgeInsetsMake(10, 15, 0, 15);
    self.textView.text = self.license.text;

    [self.view addSubview:self.textView];
    [self.textView constrainEdgesTo:self.view];
}

@end
