//
//  MCLDraftBarView.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLDraftBarView.h"

#import "UIView+addConstraints.h"
#import "MCLDependencyBag.h"
#import "MCLRouter+composeMessage.h"
#import "MCLThemeManager.h"
#import "MCLDraftManager.h"
#import "MCLDraft.h"


@interface MCLDraftBarView ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *subjectButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@end

@implementation MCLDraftBarView

- (instancetype)initWithBag:(id<MCLDependencyBag>)bag
{
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    self.bag = bag;

    [self configureSubviews];

    return self;
}


#pragma mark - Configuration

- (void)configureSubviews
{
    [[NSBundle mainBundle] loadNibNamed:@"MCLDraftBarView" owner:self options:nil];

    [self addSubview:self.contentView];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView constrainEdgesTo:self];

    self.editButton.imageView.image = [self.editButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.editButton.imageView.tintColor = [self.bag.themeManager.currentTheme textColor];

    [self.subjectButton setTitle:self.bag.draftManager.current.subject forState:UIControlStateNormal];

    self.deleteButton.imageView.image = [self.deleteButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.deleteButton.imageView.tintColor = [self.bag.themeManager.currentTheme backgroundColor];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(subjectButtonPressed:)];
    [self addGestureRecognizer:tapGestureRecognizer];
}

#pragma mark - Actions

- (IBAction)subjectButtonPressed:(id)sender
{
    [self.bag.router modalToEditDraft:self.bag.draftManager.current];
}

- (IBAction)deleteButtonPressed:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"draftbar_delete_alert_title"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"draftbar_delete_alert_button_delete", nil)
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction *action) {
                                                          [self.bag.draftManager removeCurrent];
                                                          [self dismiss];
                                                      }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"draftbar_delete_alert_button_save", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          [self dismiss];
                                                      }]];
    [self.bag.router.masterNavigationController presentViewController:alertController animated:YES completion:nil];
}

- (void)dismiss
{
    [self.bag.router.masterNavigationController setToolbarHidden:YES animated:YES];
}

@end
