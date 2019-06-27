//
//  MCLSearchQuery.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@interface MCLSearchQuery : NSObject

@property (strong, nonatomic, readonly) NSString *phrase;
@property (assign, nonatomic, readonly) BOOL searchInBody;
@property (strong, nonatomic, readonly) NSString *username;
@property (strong, nonatomic, readonly) NSNumber *board;
@property (strong, nonatomic, readonly) NSDictionary *dictionary;

+ (MCLSearchQuery *)searchQueryWithPhrase:(NSString *)phrase searchInBody:(BOOL)searchInBody username:(NSString *)username board:(NSNumber *)board;

@end
