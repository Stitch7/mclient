//
//  MCLNoDataView.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLNoDataInfo;
@protocol MCLNoDataViewPresentingViewController;

@interface MCLNoDataView : UIView

- (instancetype)initWithInfo:(MCLNoDataInfo *)info parentViewController:(id <MCLNoDataViewPresentingViewController>)parentVC;
- (void)updateVisibility;

@end
