//
//  MCLMessageTableViewCell.h
//  mclient
//
//  Created by Christopher Reitz on 26.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MCLMessageTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *messageSubjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageAuthorLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageDateLabel;

@end
