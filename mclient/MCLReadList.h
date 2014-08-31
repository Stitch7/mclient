//
//  MCLReadList.h
//  mclient
//
//  Created by Christopher Reitz on 31.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCLReadList : NSObject

- (void)addMessageId:(NSNumber *)messageId;
- (BOOL)messageIdIsRead:(NSNumber *)messageId;

@end
