//
//  MCLLicense.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@interface MCLLicense : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *text;

+ (instancetype)licenseWithName:(NSString *)name andText:(NSString *)text;

@end
