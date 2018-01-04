//
//  MCLBoardTableViewCell.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLTheme;
@class MCLBoard;

extern NSString *const MCLBoardTableViewCellIdentifier;

@interface MCLBoardTableViewCell : UITableViewCell

@property (weak, nonatomic) MCLBoard *board;
@property (strong, nonatomic) id <MCLTheme> currentTheme;

@end
