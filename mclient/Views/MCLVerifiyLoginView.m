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
    [super configureSubviews];
    
    [self setBackgroundColor:[UIColor clearColor]];

    self.label.textColor = [UIColor blackColor];
    self.label.text = NSLocalizedString(@"Verifying login data…", nil);
    self.label.font = [UIFont systemFontOfSize:13.0f];
}

- (void)loginStatusWithUsername:(NSString *)username
{
    [self.spinner stopAnimating];
    self.label.text = [NSString stringWithFormat:NSLocalizedString(@"Welcome %@", nil), username];
}

- (void)loginStatusNoLogin
{
    [self.spinner stopAnimating];
    self.label.text = NSLocalizedString(@"You are not logged in", nil);
}

@end
