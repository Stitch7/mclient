//
//  MCLBoard.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLBoard.h"

@implementation MCLBoard

+ (id) boardWithId:(int)inId name:(NSString *)inName
{
    MCLBoard *board = [[MCLBoard alloc] init];

    board.id = inId;
    board.name = inName;
    
    return board;
}

@end
