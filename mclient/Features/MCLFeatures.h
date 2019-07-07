//
//  MCLFeatures.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLFeatures+Names.h"

typedef NS_ENUM(NSUInteger, kMCLFeatureStage) {
    kMCLFeatureStageDevelopment,
    kMCLFeatureStageTesting,
    kMCLFeatureStageStore
};

@interface MCLFeatures : NSObject

@property (assign, nonatomic) NSUInteger stage;

- (instancetype)initWithStage:(NSUInteger)stage;
- (BOOL)isFeatureWithNameEnabled:(NSString *)name;

@end
