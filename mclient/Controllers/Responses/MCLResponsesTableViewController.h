//
//  MCLResponsesTableViewController.h
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageResponsesRequest.h"

@protocol MCLDependencyBag;

@interface MCLResponsesTableViewController : UITableViewController

@property (strong, nonatomic) id <MCLDependencyBag> bag;

@end
