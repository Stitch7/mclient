//
//  MCLBoard.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLBoard.h"

@implementation MCLBoard

+ (id)boardWithId:(NSNumber *)inBoardId name:(NSString *)inName
{
    MCLBoard *board = [[MCLBoard alloc] init];

    board.boardId = inBoardId;
    board.name = inName;
    
    return board;
}

@end
