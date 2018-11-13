//
//  MCLSearchFormViewDelegate.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLSearchFormView;
@class MCLSearchQuery;

@protocol MCLSearchFormViewDelegate <NSObject>

@required
- (void)searchFormView:(MCLSearchFormView *)searchFormView firedWithSearchQuery:(MCLSearchQuery *)searchQuery;
- (void)searchFormView:(MCLSearchFormView *)searchFormView firedWithError:(NSError *)error;

@end
