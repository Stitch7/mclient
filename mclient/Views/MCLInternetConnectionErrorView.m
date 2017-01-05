//
//  MCLInternetConnectionErrorView.m
//  mclient
//
//  Created by Christopher Reitz on 26.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLInternetConnectionErrorView.h"

@implementation MCLInternetConnectionErrorView

- (void)configure
{
    self.label.text = NSLocalizedString(@"No Internet Connection", nil);
    self.image.image = [UIImage imageNamed:@"errorInternetConnection.png"];
}

@end
