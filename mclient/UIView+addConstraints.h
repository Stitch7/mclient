//
//  UIView+addConstraints.h
//  mclient
//
//  Created by Christopher Reitz on 30/12/2016.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (addConstraints)

- (void)addConstraints:(NSString *)string views:(NSDictionary<NSString *, id> *)views;

@end
