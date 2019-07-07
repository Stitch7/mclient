//
//  MCLUserSearchFormView.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLUserSearchFormViewDelegate;
@protocol MCLDependencyBag;
@class MCLTextField;

@interface MCLUserSearchFormView : UIView

@property (weak, nonatomic) id<MCLUserSearchFormViewDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet MCLTextField *searchTextField;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;

@end
