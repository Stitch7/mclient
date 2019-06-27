//
//  MCLSearchFormView.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSearchFormView.h"

#import "UIView+addConstraints.h"
#import "MCLDependencyBag.h"
#import "MCLThemeManager.h"
#import "MCLSoundEffectPlayer.h"
#import "MCLSearchFormViewDelegate.h"
#import "MCLSearchQuery.h"
#import "MCLBoard.h"
#import "MCLTextField.h"
#import "MCLPickerTextField.h"


@interface MCLSearchFormView () <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) UIPickerView *boardPickerView;
@property (strong, nonatomic) NSArray<MCLBoard *> *boards;

@end

@implementation MCLSearchFormView

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag boards:(NSArray<MCLBoard *>*)boards
{
    self = [super initWithFrame:CGRectNull];
    if (!self) return nil;

    self.bag = bag;

    NSMutableArray *extendedBoards = [[NSMutableArray alloc] init];
    [extendedBoards addObject:[MCLBoard boardWithId:@-1 name:NSLocalizedString(@"search_all_boards", nil)]];
    [extendedBoards addObjectsFromArray:boards];
    self.boards = extendedBoards;

    [self configureSubviews];

    return self;
}

#pragma mark - Configuration

- (void)configureSubviews
{
    id <MCLTheme> currentTheme = self.bag.themeManager.currentTheme;

    [[NSBundle mainBundle] loadNibNamed:@"MCLSearchFormView" owner:self options:nil];
    [self addSubview:self.contentView];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView constrainEdgesTo:self];

    UITapGestureRecognizer *backgroundTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundViewTouched:)];
    [self.contentView addGestureRecognizer:backgroundTapGestureRecognizer];

    self.phraseTextField.delegate = self;
    self.usernameTextField.delegate = self;
    self.boardTextField.delegate = self;

    self.phraseTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"search_phrase", nil)
                                                                                 attributes:@{NSForegroundColorAttributeName:[currentTheme placeholderTextColor]}];
    self.usernameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"search_user", nil)
                                                                                   attributes:@{NSForegroundColorAttributeName:[currentTheme placeholderTextColor]}];
    self.searchInBodyLabel.text = NSLocalizedString(@"search_in_subject", nil);
    [self.searchButton setTitle:NSLocalizedString(@"search_button", nil) forState:UIControlStateNormal];

    self.phraseTextField.returnKeyType = UIReturnKeySearch;
    self.phraseTextField.backgroundColor = [currentTheme searchFieldBackgroundColor];
    self.phraseTextField.textColor = [currentTheme searchFieldTextColor];

    self.usernameTextField.returnKeyType = UIReturnKeySearch;
    self.usernameTextField.backgroundColor = [currentTheme searchFieldBackgroundColor];
    self.usernameTextField.textColor = [currentTheme searchFieldTextColor];

    self.boardTextField.text = [[self.boards firstObject] name];
    self.boardTextField.backgroundColor = [currentTheme searchFieldBackgroundColor];
    self.boardTextField.textColor = [currentTheme searchFieldTextColor];

    self.boardPickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
    self.boardPickerView.delegate = self;
    self.boardPickerView.dataSource = self;
    self.boardPickerView.showsSelectionIndicator = YES;
    self.boardTextField.inputView = self.boardPickerView;

    self.searchInBodySwitch.on = NO;

    self.searchButton.showsTouchWhenHighlighted = YES;
    self.searchButton.titleLabel.font = [UIFont systemFontOfSize:16.0f];
    [self.searchButton setTitleColor:self.tintColor forState:UIControlStateNormal];
    [self.searchButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    UIImage *searchButtonImage = [[UIImage imageNamed:@"searchButtonSmall"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.searchButton setImage:searchButtonImage forState:UIControlStateNormal];
    self.searchButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 15.0f, 0.0f, 0.0f);
    self.searchButton.contentEdgeInsets = UIEdgeInsetsMake(10.0f, 15.0f, 10.0f, 15.0f);
    self.searchButton.layer.borderWidth = 1.0f;
    self.searchButton.layer.cornerRadius = 5.0f;
    self.searchButton.layer.borderColor = self.tintColor.CGColor;

    [self.searchButton addTarget:self action:@selector(searchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - UITextFieldDelegate

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (self.boardTextField.isFirstResponder) {
        return NO;
    }

    return [super canPerformAction:action withSender:sender];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.boardTextField) {
        return NO;
    }

    [self resetErrorFromTextField:self.phraseTextField];
    [self resetErrorFromTextField:self.usernameTextField];

    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self searchButtonPressed:textField];

    return NO;
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (pickerView == self.boardPickerView) {
        return [self.boards[row] name];
    }

    return nil;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (pickerView == self.boardPickerView) {
        self.boardTextField.text = [self.boards[row] name];
        self.boardTextField.tag = row;
    }
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == self.boardPickerView) {
        return [self.boards count];
    }

    return 0;
}

#pragma mark - Actions

- (void)backgroundViewTouched:(UIGestureRecognizer *)sender
{
    [self endEditing:YES];
}

- (IBAction)searchInBodySwitchValueChanged:(UISwitch *)sender
{
    [self.bag.soundEffectPlayer playSwitchSound];
}

- (void)searchButtonPressed:(id)sender
{
    [self endEditing:YES];

    if ([self validateFields]) {
        NSString *phrase = [self.phraseTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *username = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSNumber *board = [self.boards[self.boardTextField.tag] boardId];
        MCLSearchQuery *searchQuery = [MCLSearchQuery searchQueryWithPhrase:phrase
                                                               searchInBody:self.searchInBodySwitch.on
                                                                   username:username
                                                                      board:board];
        [self.delegate searchFormView:self firedWithSearchQuery:searchQuery];
    }
}

#pragma mark - Validation

- (BOOL)validateFields
{
    if (self.phraseTextField.text.length > 0 || self.usernameTextField.text.length > 0) {
        return YES;
    }

    [self markTextFieldAsError:self.phraseTextField];
    [self markTextFieldAsError:self.usernameTextField];

    return NO;
}

- (void)markTextFieldAsError:(UITextField *)textField
{
    textField.layer.borderWidth = 1.0f;
    textField.layer.cornerRadius = 6.0f;
    textField.layer.borderColor = [[UIColor redColor] CGColor];
}

- (void)resetErrorFromTextField:(UITextField *)textField
{
    textField.layer.borderWidth = self.boardTextField.layer.borderWidth;
    textField.layer.cornerRadius = self.boardTextField.layer.cornerRadius;
    textField.layer.borderColor = self.boardTextField.layer.borderColor;
}

@end
