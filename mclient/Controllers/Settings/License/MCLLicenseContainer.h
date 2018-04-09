//
//  MCLLicenseContainer.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLLicense;

@interface MCLLicenseContainer : NSObject

- (NSInteger)count;
- (MCLLicense *)licenseAtIndex:(NSInteger)index;

@end
