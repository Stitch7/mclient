//
//  MCLLoadingTableViewCell.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLPacmanLoadingView;

extern NSString *const MCLLoadingTableViewCellIdentifier;

@interface MCLLoadingTableViewCell : UITableViewCell

- (instancetype)initWithLoadingView:(MCLPacmanLoadingView *)loadingView;

@end