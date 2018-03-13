//
//  MCLEditTextRequest.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRequest.h"

@protocol MCLHTTPClient;
@class MCLMessage;

@interface MCLEditTextRequest : NSObject <MCLRequest>

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient message:(MCLMessage *)message;

@end
