//
//  UIColor+Hex.m
//  mclient
//
//  Created by Christopher Reitz on 15/01/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import "UIColor+Hex.h"

@implementation UIColor (Hex)

- (uint)hex {
    CGFloat red, green, blue, alpha;
    if (![self getRed:&red green:&green blue:&blue alpha:&alpha]) {
        [self getWhite:&red alpha:&alpha];
        green = red;
        blue = red;
    }

    red = roundf(red * 255.f);
    green = roundf(green * 255.f);
    blue = roundf(blue * 255.f);
    alpha = roundf(alpha * 255.f);
    
    return ((uint)alpha << 24) | ((uint)red << 16) | ((uint)green << 8) | ((uint)blue);
}

- (NSString*)cssString {
    uint hex = [self hex];
    if ((hex & 0xFF000000) == 0xFF000000)
        return [NSString stringWithFormat:@"#%06x", hex & 0xFFFFFF];
    
    return [NSString stringWithFormat:@"#%08x", hex];
}

@end
