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
    self.label.text = self.labelText ?: NSLocalizedString(@"M!service Error", nil);
    self.image.image = [UIImage imageNamed:@"errorMService.png"];
}

@end
