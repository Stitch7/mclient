//
//  MCLLicenseViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;
@class MCLLicense;

@interface MCLLicenseViewController : UIViewController

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag andLicense:(MCLLicense *)license;

@end
