//
//  MCLUserSearchFormView.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLUserSearchFormView.h"

#import "MCLDependencyBag.h"
#import "MCLUserSearchFormViewDelegate.h"
#import "UIView+addConstraints.h"
#import "MCLTextField.h"


@interface MCLUserSearchFormView () <UITextFieldDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;

@end

@implementation MCLUserSearchFormView

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super initWithFrame:CGRectNull];
    if (!self) return nil;

    self.bag = bag;

    [self configureSubviews];

    return self;
}

#pragma mark - Configuration

- (void)configureSubviews
{
    id <MCLTheme> currentTheme = self.bag.themeManager.currentTheme;

    [[NSBundle mainBundle] loadNibNamed:@"MCLUserSearchFormView" owner:self options:nil];
    [self addSubview:self.contentView];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView constrainEdgesTo:self];

    UITapGestureRecognizer *backgroundTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundViewTouched:)];
    [self.contentView addGestureRecognizer:backgroundTapGestureRecognizer];


    self.searchTextField.delegate = self;
    self.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"user_search_placeholder", nil)
                                                                                 attributes:@{NSForegroundColorAttributeName:[currentTheme placeholderTextColor]}];

    self.searchTextField.returnKeyType = UIReturnKeySearch;
    self.searchTextField.backgroundColor = [currentTheme searchFieldBackgroundColor];
    self.searchTextField.textColor = [currentTheme searchFieldTextColor];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self searchButtonPressed:textField];

    return NO;
}

#pragma mark - Actions

- (void)backgroundViewTouched:(UIGestureRecognizer *)sender
{
    [self endEditing:YES];
}

- (void)searchButtonPressed:(id)sender
{
    if ([self validateFields]) {
        [self endEditing:YES];
        NSString *searchText = [self.searchTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [self.delegate userSearchFormView:self firedWithSearchText:searchText];
    }
}

- (BOOL)validateFields
{
    if (self.searchTextField.text.length > 0) {
        return YES;
    }

    return NO;
}


@end
