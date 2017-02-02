//
//  MCLReadListMigrator.m
//  mclient
//
//  Created by Christopher Reitz on 31/01/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import "MCLReadListMigrator.h"
#import "MCLMServiceConnector.h"

#define kUserDefaultsKey @"MCLReadList"
#define kUserDefaultsMigratedKey @"MCLReadListMigrated-TMP"

@implementation MCLReadListMigrator

- (void)migrateWithLoginData:(NSDictionary *)loginData
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:kUserDefaultsMigratedKey]) {
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *readList = [userDefaults objectForKey:kUserDefaultsKey];
        if (!readList) {
            return;
        }

        NSError *mServiceError;
        [[MCLMServiceConnector sharedConnector] importReadList:readList login:loginData error:&mServiceError];

        if (mServiceError) {
            NSLog(@"%@", mServiceError);
            return;
        }

//        [userDefaults removeObjectForKey:kUserDefaultsKey];
        [userDefaults setBool:YES forKey:kUserDefaultsMigratedKey];
    });
}

@end
