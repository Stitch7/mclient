//
//  MCLSearchQuery.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSearchQuery.h"

@interface MCLSearchQuery ()

@property (strong, nonatomic, readwrite) NSString *phrase;
@property (assign, nonatomic, readwrite) BOOL searchInBody;
@property (strong, nonatomic, readwrite) NSString *username;
@property (strong, nonatomic, readwrite) NSNumber *board;
@property (strong, nonatomic, readwrite) NSNumber *days;

@end

@implementation MCLSearchQuery

+ (MCLSearchQuery *)searchQueryWithPhrase:(NSString *)phrase searchInBody:(BOOL)searchInBody username:(NSString *)username board:(NSNumber *)board days:(NSNumber *)days
{
    MCLSearchQuery *searchQuery = [[MCLSearchQuery alloc] init];
    searchQuery.phrase = phrase;
    searchQuery.searchInBody = searchInBody;
    searchQuery.username = username;
    searchQuery.board = board;
    searchQuery.days = days;

    return searchQuery;
}

- (NSDictionary *)dictionary
{
    return @{@"phrase": self.phrase ?: @"",
             @"searchInBody": self.searchInBody ? @"1" : @"0",
             @"username": self.username ?: @"",
             @"board": [self.board stringValue] ?: @"",
             @"days": [self.days stringValue] ?: @""};
}

@end