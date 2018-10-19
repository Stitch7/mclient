//
//  MCLLoginSecureStore.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLLoginSecureStore <NSObject>

- (nullable NSString *)stringForKey:(nonnull NSString *)key;
- (void)setString:(nullable NSString *)aString forKey:(NSString *)aKey;
- (BOOL)removeObjectForKey:(NSString *)key;

@end
