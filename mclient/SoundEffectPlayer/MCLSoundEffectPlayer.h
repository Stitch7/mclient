//
//  MCLSoundEffectPlayer.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLSettings;

@interface MCLSoundEffectPlayer : NSObject

- (instancetype)initWithSettings:(MCLSettings *)settings;

- (void)playCreatePostingSound;
- (void)playEditPostingSound;
- (void)playReloadSound;
- (void)playMarkAllAsReadSound;
- (void)playAddThreadToFavoritesSound;
- (void)playRemoveThreadFromFavoritesSound;
- (void)playAddThreadToKillfileSound;
- (void)playRemoveThreadFromKillfileSound;
- (void)playLoginFailedSound;
- (void)playCopyLinkSound;
- (void)playErrorSound;
- (void)playSwitchSound;
- (void)playTickSound;
- (void)playPrivateMessageReceivedSound;
- (void)playSecretFoundSound;

@end
