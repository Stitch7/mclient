//
//  MCLComposeMessageViewControllerDelegate.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLMessage;

@protocol MCLComposeMessageViewControllerDelegate <NSObject>

@required
- (void)message:(MCLMessage *)message sentWithType:(NSUInteger)type;

@end
