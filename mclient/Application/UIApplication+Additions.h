//
//  UIApplication+Additions.h
//  mclient
//
//  Created by Christopher Reitz on 11/03/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (Additions)

- (NSInteger)incrementApplicationIconBadgeNumber;
- (NSInteger)decrementApplicationIconBadgeNumber;

@end
