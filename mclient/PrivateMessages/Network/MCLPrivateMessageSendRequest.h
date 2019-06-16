//
//  MCLPrivateMessageSendRequest.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLHTTPClient;
@class MCLPrivateMessage;

@interface MCLPrivateMessageSendRequest : NSObject <MCLRequest>

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient privateMessage:(MCLPrivateMessage *)privateMessage;

@end
