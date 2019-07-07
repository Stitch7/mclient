//
//  MCLFeature.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLFeatures.h"

@interface MCLFeatures ()

@property (strong, nonatomic) NSDictionary *keys;

@end

@implementation MCLFeatures

#pragma mark - Initializers

- (instancetype)initWithStage:(NSUInteger)stage
{
    self = [super init];
    if (!self) return nil;

    self.stage = stage;
    [self loadKeys];

    return self;
}

#pragma mark - Public

- (BOOL)isFeatureWithNameEnabled:(NSString *)name
{
    if (self.keys == nil || [self.keys objectForKey:name] == nil) {
        return NO;
    }

    return [[self.keys objectForKey:name] boolValue];
}

#pragma mark - Private

- (void)loadKeys
{
    NSString *plistName = [self plistNameForStage:self.stage];
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
    self.keys = [NSDictionary dictionaryWithContentsOfFile:plistPath];
}

- (NSString *)plistNameForStage:(NSUInteger)stage
{
    NSString *name;
    switch (stage) {
        case kMCLFeatureStageDevelopment:
        default:
            name = @"features-development";
            break;

        case kMCLFeatureStageTesting:
            name = @"features-testing";
            break;

        case kMCLFeatureStageStore:
            name = @"features-store";
            break;
    }

    return name;
}

@end
