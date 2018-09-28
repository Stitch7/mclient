//
//  MCLErrorViewController.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;
@class MCLMServiceErrorView;

@interface MCLErrorViewController : UIViewController

@property (strong, nonatomic) MCLMServiceErrorView *errorView;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag error:(NSError *)error;

@end
