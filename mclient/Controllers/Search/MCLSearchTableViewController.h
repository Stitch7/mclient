//
//  MCLSearchTableViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;
@class MCLBoard;

@interface MCLSearchTableViewController : UITableViewController

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag boards:(NSArray<MCLBoard *>*)boards;

@end
