//
//  MCLVerifiyLoginView.m
//  mclient
//
//  Created by Christopher Reitz on 25.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLVerifiyLoginView.h"

@implementation MCLVerifiyLoginView

- (void)configureSubviews
{
    [self setBackgroundColor:[UIColor clearColor]];
    self.label.text = @"Verifying login data…";
    self.label.font = [UIFont systemFontOfSize:13.0f];

    self.spaceBetwennSpinnerAndLabel = 10;
}

- (void)loginStatusWithUsername:(NSString *)username
{
    [self.spinner stopAnimating];
    self.label.text = [NSString stringWithFormat:@"Welcome %@", username];
    [self layoutSubviews];
}

- (void)loginStausNoLogin
{
    [self.spinner stopAnimating];
    self.label.text = @"You are not logged in";
    [self layoutSubviews];
}

@end
