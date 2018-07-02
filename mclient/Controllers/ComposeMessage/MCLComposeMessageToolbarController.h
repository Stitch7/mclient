//
//  MCLComposeMessageToolbarController.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLComposeMessageViewController;

#import "MCLMessageTextViewToolbarDelegate.h"

@interface MCLComposeMessageToolbarController : NSObject <UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCLMessageTextViewToolbarDelegate>

- (instancetype)initWithParentViewController:(MCLComposeMessageViewController *)parentViewController;

@end
