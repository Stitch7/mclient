//
//  MCLMessage.h
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCLMessage : NSObject

@property (assign) int id;
@property (strong) NSString *author;
@property (strong) NSString *subject;
@property (strong) NSString *date;
@property (strong) NSString *text;

+ (id) messageWithId:(int)inId author:(NSString *)inAuthor subject:(NSString *)inSubject date:(NSString *)inDate text:(NSString *)inText;

@end
