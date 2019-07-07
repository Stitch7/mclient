//
//  MCLSettingsFontSizeViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;
@protocol MCLSettingsFontSizeViewControllerDelegate;

@interface MCLSettingsFontSizeViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (weak) id<MCLSettingsFontSizeViewControllerDelegate> delegate;

@end

@protocol MCLSettingsFontSizeViewControllerDelegate <NSObject>

- (void)settingsFontSizeViewController:(MCLSettingsFontSizeViewController *)inController fontSizeChanged:(int)fontSize;

@end
