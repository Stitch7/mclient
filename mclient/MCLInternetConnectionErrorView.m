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
    self.label.text = @"No Internet Connection";
    self.image.image = [UIImage imageNamed:@"errorConnection.png"];
}

@end
