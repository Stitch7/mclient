//
//  MCLSearchFormView.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLSearchFormViewDelegate;
@protocol MCLDependencyBag;
@class MCLTextField;
@class MCLPickerTextField;
@class MCLBoard;

@interface MCLSearchFormView : UIView

@property (weak, nonatomic) id<MCLSearchFormViewDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIStackView *mainStackView;
@property (weak, nonatomic) IBOutlet MCLTextField *phraseTextField;
@property (weak, nonatomic) IBOutlet MCLTextField *usernameTextField;
@property (weak, nonatomic) IBOutlet MCLPickerTextField *boardTextField;
@property (weak, nonatomic) IBOutlet UILabel *searchInBodyLabel;
@property (weak, nonatomic) IBOutlet UISwitch *searchInBodySwitch;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag boards:(NSArray<MCLBoard *>*)boards;

@end
