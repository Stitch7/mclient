//
//  MCLLicenseContainer.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLicenseContainer.h"
#import "MCLLicenseContainer+Texts.h"
#import "MCLLicense.h"


@interface MCLLicenseContainer ()

@property (strong, nonatomic) NSArray<__kindof MCLLicense *> *licenses;

@end

@implementation MCLLicenseContainer

#pragma mark - Initializers

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    [self initLicenses];

    return self;
}

- (void)initLicenses
{
    self.licenses = @[[MCLLicense licenseWithName:@"EDSunriseSet" andText:MCLLicenseEDSunriseSet],
                      [MCLLicense licenseWithName:@"BBBadgeBarButtonItem" andText:MCLLicenseBBBadgeBarButtonItem],
                      [MCLLicense licenseWithName:@"MGSwipeTableCell" andText:MCLLicenseMGSwipeTableCell],
                      [MCLLicense licenseWithName:@"Valet" andText:MCLLicenseValet],
                      [MCLLicense licenseWithName:@"DGActivityIndicatorView" andText:MCLLicenseDGActivityIndicatorView],
                      [MCLLicense licenseWithName:@"AsyncBlockOperation" andText:MCLLicenseAsyncBlockOperation],
                      [MCLLicense licenseWithName:@"ImgurSession" andText:MCLLicenseImgurSession],
                      [MCLLicense licenseWithName:@"MRProgress" andText:MCLLicenseMRProgress],
                      [MCLLicense licenseWithName:@"HockeySDK" andText:MCLLicenseHockeySDK],
                      [MCLLicense licenseWithName:@"SwiftyGiphy" andText:MCLLicenseSwiftyGiphy]];
}

#pragma mark - Public Methods

- (NSInteger)count
{
    return [self.licenses count];
}

- (MCLLicense *)licenseAtIndex:(NSInteger)index
{
    return self.licenses[index];
}

@end
