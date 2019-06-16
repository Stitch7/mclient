//
//  MCLUserSearchFormView.h
//  mclient
//
//  Created by Christopher Reitz on 03.03.19.
//  Copyright © 2019 Christopher Reitz. All rights reserved.
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
