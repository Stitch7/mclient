//
//  MCLInternetConnectionErrorView.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLInternetConnectionErrorView.h"

@implementation MCLInternetConnectionErrorView

- (void)configure
{
    self.label.text = NSLocalizedString(@"No Internet Connection", nil);
    self.image.image = [UIImage imageNamed:@"errorInternetConnection"];
}

@end
