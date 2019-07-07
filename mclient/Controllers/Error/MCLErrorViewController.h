//
//  MCLErrorViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;
@class MCLErrorView;

typedef NS_ENUM(NSUInteger, kMCLErrorType) {
    kMCLErrorTypeNoInternetConnection,
    kMCLErrorTypeGeneral
};

@interface MCLErrorViewController : UIViewController

@property (assign, nonatomic) NSUInteger errorType;
@property (strong, nonatomic) MCLErrorView *errorView;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag type:(NSUInteger)type error:(NSError *)error;

@end
