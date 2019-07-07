//
//  MCLMessageTextView.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLTextView.h"

@protocol MCLMessageTextViewErrorHandler;

@interface MCLMessageTextView : MCLTextView <UITextViewDelegate>

@property (assign, nonatomic) BOOL changed;
@property (weak) id<MCLMessageTextViewErrorHandler> errorHandler;

- (void)formatBold;
- (void)formatItalic;
- (void)formatUnderline;
- (void)formatStroke;
- (void)formatSpoiler;
- (void)addLink:(NSURL *)url;
- (void)addImage:(NSURL *)url;

@end

@protocol MCLMessageTextViewErrorHandler <NSObject>

- (void)invalidURLPasted;
- (void)invalidImageURLPasted;

@end
