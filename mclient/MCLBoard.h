//
//  MCLBoard.h
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCLBoard : NSObject

@property (strong, nonatomic) NSNumber *boardId;
@property (strong, nonatomic) NSString *name;

+ (id)boardWithId:(NSNumber *)inBoardId name:(NSString *)inName;

@end
