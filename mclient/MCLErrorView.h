//
//  MCLErrorView.h
//  mclient
//
//  Created by Christopher Reitz on 13.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MCLErrorView : UIView

@property (strong, nonatomic) UILabel *label;
@property (strong, nonatomic) NSString *labelText;
@property (strong, nonatomic) UIImageView *image;
@property (strong, nonatomic) UILabel *subLabel;
@property (assign, nonatomic) BOOL hideSubLabel;

- (id)initWithFrame:(CGRect)frame hideSubLabel:(BOOL)hideSubLabel;
- (id)initWithFrame:(CGRect)frame andText:(NSString *)text;
- (id)initWithFrame:(CGRect)frame andText:(NSString *)text hideSubLabel:(BOOL)hideSubLabel;

@end
