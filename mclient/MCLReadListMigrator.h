//
//  MCLReadListMigrator.h
//  mclient
//
//  Created by Christopher Reitz on 31/01/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//
//  TODO: This class can be removed in next release

#import <Foundation/Foundation.h>

@interface MCLReadListMigrator : NSObject

- (void)migrateWithLoginData:(NSDictionary *)loginData;

@end
