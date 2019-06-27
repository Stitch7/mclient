//
//  MCLRouter+composeMessage.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRouter.h"

@class MCLBoard;
@class MCLMessage;
@class MCLDraft;
@class MCLComposeMessageViewController;
@class MCLComposeMessagePreviewViewController;
@class MCLDraftTableViewController;
@class SwiftyGiphyHelper;

@interface MCLRouter (composeMessage)

- (MCLComposeMessageViewController *)modalToComposeThreadToBoard:(MCLBoard *)board;
- (MCLComposeMessageViewController *)modalToComposeReplyToMessage:(MCLMessage *)message;
- (MCLComposeMessageViewController *)modalToEditMessage:(MCLMessage *)message;
- (MCLComposeMessageViewController *)modalToEditDraft:(MCLDraft *)draft;
- (MCLComposeMessagePreviewViewController *)pushToPreviewForMessage:(MCLMessage *)message;

- (MCLDraftTableViewController *)pushToDrafts;

- (UIImagePickerController *)modalToImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType fromButton:(UIBarButtonItem *)button;

- (SwiftyGiphyHelper *)modalToGiphy;
- (void)dismissModalWithCompletion: (void (^)(void))completion;

@end
