//
//  MCLErrorView.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@interface MCLErrorView : UIView

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UILabel *label;
@property (strong, nonatomic) NSString *labelText;
@property (strong, nonatomic) UIImageView *image;
@property (strong, nonatomic) UIButton *button;
@property (strong, nonatomic) UIButton *gameButton;
@property (assign, nonatomic) BOOL hideSubLabel;

- (instancetype)initWithFrame:(CGRect)frame hideSubLabel:(BOOL)hideSubLabel;
- (instancetype)initWithFrame:(CGRect)frame andText:(NSString *)text;
- (instancetype)initWithFrame:(CGRect)frame andText:(NSString *)text hideSubLabel:(BOOL)hideSubLabel;

@end
