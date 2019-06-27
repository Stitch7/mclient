//
//  MCLDraftTableViewCell.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;
@class MCLDraft;

extern NSString *const MCLDraftTableViewCellIdentifier;

@interface MCLDraftTableViewCell : UITableViewCell

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (weak, nonatomic) MCLDraft *draft;

@end
