//
//  MCLThreadTableViewCell.h
//  mclient
//
//  Created by Christopher Reitz on 26.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDBadgedCell.h"

//@interface MCLThreadTableViewCell : UITableViewCell
@interface MCLThreadTableViewCell : TDBadgedCell

@property (weak, nonatomic) IBOutlet UILabel *threadSubjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *threadAuthorLabel;
@property (weak, nonatomic) IBOutlet UILabel *threadDateLabel;

@end
