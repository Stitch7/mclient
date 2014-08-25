//
//  MCLBoard.h
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCLBoard : NSObject

@property (assign) int id;
@property (strong) NSString *name;

+ (id) boardWithId:(int)inId name:(NSString *)inName;

@end
