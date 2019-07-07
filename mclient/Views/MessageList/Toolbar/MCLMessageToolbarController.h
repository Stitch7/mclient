//
//  MCLMessageToolbarController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@import AVFoundation;

#import "MCLMessageToolbarDelegate.h"


@protocol MCLDependencyBag;

@class MCLMessageToolbar;
@class MCLMessageListViewController;

@interface MCLMessageToolbarController : NSObject <AVSpeechSynthesizerDelegate, MCLMessageToolbarDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) MCLMessageToolbar *toolbar;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag messageListViewController:(MCLMessageListViewController *)messageListViewController;

- (void)stopSpeaking;

@end
