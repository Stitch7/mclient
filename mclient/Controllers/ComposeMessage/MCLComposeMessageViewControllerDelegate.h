//
//  MCLComposeMessageViewControllerDelegate.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLComposeMessageViewControllerDelegate <NSObject>

@required
- (void)messageSentWithType:(NSUInteger)type;

@optional
- (void)handleRotationChangeInBackground;

@end
