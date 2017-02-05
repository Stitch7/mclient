//
//  MCLLoadingView.h
//  mclient
//
//  Created by Christopher Reitz on 12.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MCLLoadingView : UIView

@property(strong, nonatomic) UIView *container;
@property(strong, nonatomic) UILabel *label;
@property(strong, nonatomic) UIActivityIndicatorView *spinner;

-(void)configureSubviews;

@end
