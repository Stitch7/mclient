//
//  MCLBoardTableViewCell.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLBoardTableViewCell.h"
#import "MCLBoard.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"

NSString *const MCLBoardTableViewCellIdentifier = @"BoardCell";

@implementation MCLBoardTableViewCell

- (void)setBoard:(MCLBoard *)board
{
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.frame];
    backgroundView.backgroundColor = [self.currentTheme tableViewCellSelectedBackgroundColor];
    self.selectedBackgroundView = backgroundView;

    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    self.imageView.image = board.image;
    self.textLabel.text = board.name;

    self.textLabel.textColor = [self.currentTheme textColor];
    self.textLabel.font = [UIFont systemFontOfSize:15.0f];
}

@end
