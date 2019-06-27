//
//  MCLRequest.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLHTTPClient;


@protocol MCLRequest

@property (strong, nonatomic) id <MCLHTTPClient> httpClient;

- (void)loadWithCompletionHandler:(void (^)(NSError*, NSArray*))completionHandler;

@end
