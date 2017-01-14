//
//  MCLSettingsFontSizeViewController.h
//  mclient
//
//  Created by Christopher Reitz on 14/01/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MCLSettingsFontSizeViewControllerDelegate;

@interface MCLSettingsFontSizeViewController : UIViewController <UIWebViewDelegate>

@property (weak) id<MCLSettingsFontSizeViewControllerDelegate> delegate;

@end

@protocol MCLSettingsFontSizeViewControllerDelegate <NSObject>

- (void)settingsFontSizeViewController:(MCLSettingsFontSizeViewController *)inController fontSizeChanged:(int)fontSize;

@end
