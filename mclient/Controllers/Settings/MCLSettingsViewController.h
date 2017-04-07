//
//  MCLSettingsViewController.h
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSettingsFontSizeViewController.h"

@protocol MCLDependencyBag;
@protocol MCLSettingsTableViewControllerDelegate;

@interface MCLSettingsViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate, MCLSettingsFontSizeViewControllerDelegate>

@property (weak) id<MCLSettingsTableViewControllerDelegate> delegate;
@property (strong, nonatomic) id <MCLDependencyBag> bag;

@end

@protocol MCLSettingsTableViewControllerDelegate <NSObject>

- (void)settingsTableViewControllerDidFinish:(MCLSettingsViewController *)inController loginDataChanged:(BOOL)loginDataChanged;

@end
