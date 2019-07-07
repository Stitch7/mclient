//
//  MCLBoard.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLBoard.h"

@implementation MCLBoard

+ (MCLBoard *)boardWithId:(NSNumber *)inBoardId
{
    return [self boardWithId:inBoardId name:nil];
}

+ (MCLBoard *)boardWithId:(NSNumber *)inBoardId name:(NSString *)inName
{
    MCLBoard *board = [[MCLBoard alloc] init];

    board.boardId = inBoardId;
    board.name = inName;
    
    return board;
}

+ (MCLBoard *)boardFromJSON:(NSDictionary *)json
{
    NSNumber *boardId = [json objectForKey:@"id"];
    NSString *boardName = [json objectForKey:@"name"];
    if ([boardId isEqual:[NSNull null]] || boardName.length == 0) {
        return nil;
    }

    return [MCLBoard boardWithId:boardId name:boardName];
}

- (UIImage *)image
{
    UIImage *image;
    switch ([self.boardId intValue]) {
        case 1:
            image = [UIImage imageNamed:@"boardSmalltalk"];
            break;

        case 2:
            image = [UIImage imageNamed:@"boardForSale"];
            break;

        case 4:
            image = [UIImage imageNamed:@"boardRetroNTech"];
            break;

        case 6:
            image = [UIImage imageNamed:@"boardOT"];
            break;

        case 8:
            image = [UIImage imageNamed:@"boardOnlineGaming"];
            break;

        case 26:
            image = [UIImage imageNamed:@"boardKulturbeutel"];
            break;

        default: {
            if ([self.name isEqualToString:@"EM"] || [self.name isEqualToString:@"WM"]) {
                image = [UIImage imageNamed:@"boardSoccer"];
            } else if ([self.name isEqualToString:@"E3"]) {
                image = [UIImage imageNamed:@"boardE3"];
            } else {
                image = [UIImage imageNamed:@"boardDefault"];
            }
            break;
        }
    }

    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

@end
