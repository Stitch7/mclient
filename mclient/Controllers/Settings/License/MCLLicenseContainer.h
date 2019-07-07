//
//  MCLLicenseContainer.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLLicense;

@interface MCLLicenseContainer : NSObject

- (NSInteger)count;
- (MCLLicense *)licenseAtIndex:(NSInteger)index;

@end
