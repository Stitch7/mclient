//
//  MCLRouter+composeMessage.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRouter.h"

@class MCLBoard;
@class MCLMessage;
@class MCLComposeMessageViewController;
@class MCLComposeMessagePreviewViewController;
@class SwiftyGiphyHelper;

@interface MCLRouter (composeMessage)

- (MCLComposeMessageViewController *)modalToComposeThreadToBoard:(MCLBoard *)board;
- (MCLComposeMessageViewController *)modalToComposeReplyToMessage:(MCLMessage *)message;
- (MCLComposeMessageViewController *)modalToEditMessage:(MCLMessage *)message;
- (MCLComposeMessagePreviewViewController *)pushToPreviewForMessage:(MCLMessage *)message;

- (UIImagePickerController *)modalToImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType fromButton:(UIBarButtonItem *)button;

- (SwiftyGiphyHelper *)modalToGiphy;
- (void)dismissModalWithCompletion: (void (^)(void))completion;

@end
