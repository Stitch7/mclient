//
//  MCLMServiceConnector.h
//  mclient
//
//  Created by Christopher Reitz on 02.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCLMServiceConnector : NSObject

- (BOOL)testLoginWIthUsername:(NSString *)inUsername password:(NSString *)inPassword;

@end
