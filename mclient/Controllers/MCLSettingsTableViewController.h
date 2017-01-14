//
//  MCLSettingsTableViewController.h
//  mclient
//
//  Created by Christopher Reitz on 01.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCLSettingsFontSizeViewController.h"

@protocol MCLSettingsTableViewControllerDelegate;

@interface MCLSettingsTableViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate, MCLSettingsFontSizeViewControllerDelegate>

@property (weak) id<MCLSettingsTableViewControllerDelegate> delegate;

@end

@protocol MCLSettingsTableViewControllerDelegate <NSObject>

- (void)settingsTableViewControllerDidFinish:(MCLSettingsTableViewController *)inController loginDataChanged:(BOOL)loginDataChanged;

@end
