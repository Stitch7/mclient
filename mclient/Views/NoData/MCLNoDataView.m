//
//  MCLNoDataView.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLNoDataView.h"

#import "UIView+addConstraints.h"
#import "MCLNoDataInfo.h"
#import "MCLNoDataViewPresentingViewController.h"


@interface MCLNoDataView ()

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *helpButton;

@property (strong, nonatomic) MCLNoDataInfo *info;
@property (weak, nonatomic) id <MCLNoDataViewPresentingViewController> parentVC;

@end

@implementation MCLNoDataView

#pragma mark - Initializers

- (instancetype)initWithInfo:(MCLNoDataInfo *)info parentViewController:(id <MCLNoDataViewPresentingViewController>)parentVC
{
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    self.info = info;
    self.parentVC = parentVC;

    [self configureSubviews];

    return self;
}

- (instancetype)initWithInfo:(MCLNoDataInfo *)info
{
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    self.info = info;
    self.parentVC = nil;

    [self configureSubviews];

    return self;
}

#pragma mark - Configuration

- (void)configureSubviews
{
    [[NSBundle mainBundle] loadNibNamed:@"MCLNoDataView" owner:self options:nil];

    [self addSubview:self.contentView];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView constrainEdgesTo:self];

    [self.helpButton addTarget:self action:@selector(helpButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    [self updateVisibility];
}

#pragma mark - Actions

- (void)helpButtonPressed:(UIButton *)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.info.helpTitle
                                                                   message:self.info.helpMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"noDataView_hide_noDataView", nil)
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                [self.info hide];
                                                [self.parentVC.tableView reloadData];
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];

    [self.parentVC presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Public

- (void)updateVisibility
{
    if (self.info.isHidden) {
        self.messageLabel.hidden = YES;
        self.helpButton.hidden = YES;
    } else {
        self.messageLabel.text = self.info.messageText;
        self.messageLabel.textColor = [UIColor darkGrayColor];
        self.helpButton.hidden = !self.info.hasHelp;
    }
}

@end
