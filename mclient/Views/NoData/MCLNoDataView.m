//
//  MCLNoDataView.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLNoDataView.h"

#import "UIView+addConstraints.h"

NSString * const MCLNoDataViewHelpTitleKey = @"helpTitleKey";
NSString * const MCLNoDataViewHelpMessageKey = @"helpMessageKey";

@interface MCLNoDataView ()

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *helpButton;

@property (strong, nonatomic) NSString *messageText;
@property (strong, nonatomic) NSDictionary *helpDict;
@property (weak, nonatomic) UIViewController *parentVC;

@end

@implementation MCLNoDataView

#pragma mark - Initializers

- (instancetype)initWithMessage:(NSString *)message help:(NSDictionary *)help parentViewController:(UIViewController *)parentVC
{
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    self.messageText = message;
    self.helpDict = help;
    self.parentVC = parentVC;

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

    self.messageLabel.text = self.messageText;
    self.messageLabel.textColor = [UIColor darkGrayColor];

    [self.helpButton addTarget:self action:@selector(helpButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Actions

- (void)helpButtonPressed:(UIButton *)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.helpDict[MCLNoDataViewHelpTitleKey]
                                                                   message:self.helpDict[MCLNoDataViewHelpMessageKey]
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];

    [self.parentVC presentViewController:alert animated:YES completion:nil];
}

@end
