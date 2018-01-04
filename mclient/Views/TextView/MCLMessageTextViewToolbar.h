//
//  MCLMessageTextViewToolbar.h
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLMessageTextViewToolbarDelegate;

@interface MCLMessageTextViewToolbar : UIToolbar

@property (weak) id<MCLMessageTextViewToolbarDelegate> messageTextViewToolbarDelegate;
@property (assign, nonatomic) NSUInteger type;

@end