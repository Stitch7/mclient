//
//  MCLQuote.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLQuote.h"

@implementation MCLQuote

+ (MCLQuote *)quoteFromJSON:(NSDictionary *)json
{
    MCLQuote *quote = [[MCLQuote alloc] init];

    quote.string = [json objectForKey:@"quote"];

    return quote;
}

- (NSArray *)blocks
{
    if (_blocks) {
        return _blocks;
    }

    NSMutableArray *blocks = [[NSMutableArray alloc] init];
    NSArray *rawBlocks = [self.string componentsSeparatedByString:@"\n"];
    self.quoteOfQuoteRemoved = NO;
    for (NSString *rawBlock in rawBlocks) {
        if ([rawBlock isEqualToString:@">"] ||
            [rawBlock hasPrefix:@">>"] ||
            [rawBlock hasPrefix:@">-------------"] ||
            [[rawBlock lowercaseString] hasPrefix:@">gesendet mit"]) {
            self.quoteOfQuoteRemoved = YES;
            continue;
        }
        [blocks addObject:rawBlock];
    }

    _blocks = blocks;
    return _blocks;
}

- (BOOL)hasBlocks
{
    return [self.blocks count] > 1 || self.quoteOfQuoteRemoved;
}

- (void)appendToTextField:(UITextView *)textView
{
    NSString *textViewContent = [@"\n\n" stringByAppendingString:textView.text];
    textView.text = [self.string stringByAppendingString:textViewContent];
}

@end
