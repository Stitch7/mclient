//
//  MCLDraftManager.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLMessage;
@class MCLDraft;

extern NSString * const MCLDraftsChangedNotification;

@interface MCLDraftManager : NSObject

- (MCLDraft *)current;
- (NSNumber *)count;
- (NSArray *)all;
- (MCLMessage *)draftForMessage:(MCLMessage *)message;
- (void)saveMessageAsDraft:(MCLMessage *)message;
- (void)removeDraftForMessage:(MCLMessage *)message;
- (void)removeCurrent;

@end
