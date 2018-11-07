//
//  MCLNoDataTableViewCell.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLNoDataView;

extern NSString *const MCLNoDataTableViewCellIdentifier;

@interface MCLNoDataTableViewCell : UITableViewCell

- (instancetype)initWithNoDataView:(MCLNoDataView *)noDataView;

@end
