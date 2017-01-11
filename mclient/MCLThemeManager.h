//
//  MCLThemeManager.h
//  mclient
//
//  Created by Christopher Reitz on 11/01/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, kMCLTheme) {
    kMCLThemeDefault,
    kMCLThemeNight
};

@protocol MCLTheme;

@interface MCLThemeManager : NSObject

@property (strong, nonatomic) id <MCLTheme> currentTheme;

+ (id)sharedManager;
- (void)applyTheme: (id <MCLTheme>)theme;

@end
