//
//  MCLMServiceErrorView.m
//  mclient
//
//  Created by Christopher Reitz on 26.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLMServiceErrorView.h"

@implementation MCLMServiceErrorView

- (void)configure
{
    self.label.text = @"Unable not load data";
    self.image.image = [UIImage imageNamed:@"errorResponse.png"];
}

@end
