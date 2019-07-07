//
//  MCLSettingsViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSettingsFontSizeViewController.h"

@protocol MCLDependencyBag;

extern NSString *const MCLThreadViewStyleChangedNotification;

@interface MCLSettingsViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate, MCLSettingsFontSizeViewControllerDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;

@end
