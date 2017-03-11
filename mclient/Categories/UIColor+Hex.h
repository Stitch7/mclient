//
//  UIColor+Hex.h
//  mclient
//
//  Created by Christopher Reitz on 15/01/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Hex)

- (uint)hex;
- (NSString *)cssString;

@end
