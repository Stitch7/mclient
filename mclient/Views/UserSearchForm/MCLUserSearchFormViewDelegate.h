//
//  MCLUserSearchFormViewDelegate.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLUserSearchFormView;

@protocol MCLUserSearchFormViewDelegate <NSObject>

@required
- (void)userSearchFormView:(MCLUserSearchFormView *)userSearchFormView firedWithSearchText:(NSString *)searchText;
- (void)userSearchFormView:(MCLUserSearchFormView *)userSearchFormView firedWithError:(NSError *)error;

@end
