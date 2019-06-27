//
//  MCLQuote.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@interface MCLQuote : NSObject

@property (assign, nonatomic) BOOL quoteOfQuoteRemoved;
@property (strong, nonatomic) NSString *string;
@property (strong, nonatomic) NSArray *blocks;

+ (MCLQuote *)quoteFromJSON:(NSDictionary *)json;

- (BOOL)hasBlocks;
- (void)appendToTextField:(UITextView *)textView;

@end
