//
//  MCLMServiceErrorView.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMServiceErrorView.h"

@implementation MCLMServiceErrorView

- (void)configure
{
    self.label.text = self.labelText ?: NSLocalizedString(@"m!service Error", nil);
    self.image.image = [UIImage imageNamed:@"errorMservice2"];
}

@end
