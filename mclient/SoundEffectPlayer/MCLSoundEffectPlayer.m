//
//  MCLSoundEffectPlayer.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSoundEffectPlayer.h"

#import "MCLSettings.h"

@import AVFoundation;
@import AudioToolbox;

@interface MCLSoundEffectPlayer ()

@property (strong, nonatomic) MCLSettings *settings;

@end

@implementation MCLSoundEffectPlayer

#pragma mark - Initializers

- (instancetype)initWithSettings:(MCLSettings *)settings
{
    self = [super init];
    if (!self) return nil;

    self.settings = settings;

    return self;
}

#pragma mark - Private

- (void)playSoundWithName:(NSString *)resource
{
    if (![self.settings isSettingActivated:MCLSettingSoundEffectsEnabled orDefault:YES]) {
        return;
    }

    NSString *soundPath = [[NSBundle mainBundle] pathForResource:resource ofType:@"caf"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPath], &soundID);
    AudioServicesPlaySystemSound(soundID);
}

#pragma mark - Public

- (void)playCreatePostingSound
{
    [self playSoundWithName:@"createPosting"];
}

- (void)playEditPostingSound
{
    [self playSoundWithName:@"editPosting"];
}

- (void)playReloadSound
{
    [self playSoundWithName:@"reload"];
}

- (void)playMarkAllAsReadSound
{
    [self playSoundWithName:@"markAllAsRead"];
}

- (void)playAddThreadToFavoritesSound
{
    [self playSoundWithName:@"addThreadToFavorites"];
}

- (void)playRemoveThreadFromFavoritesSound
{
    [self playSoundWithName:@"removeThreadFromFavorites"];
}

- (void)playAddThreadToKillfileSound
{
    [self playSoundWithName:@"addThreadToKillfile"];
}

- (void)playRemoveThreadFromKillfileSound
{
    [self playSoundWithName:@"removeThreadFromKillfile"];
}

- (void)playLoginFailedSound
{
    [self playSoundWithName:@"loginFailed"];
}

- (void)playCopyLinkSound
{
    [self playSoundWithName:@"copyLink"];
}

- (void)playErrorSound
{
    [self playSoundWithName:@"error"];
}

- (void)playSwitchSound
{
    [self playSoundWithName:@"switch"];
}

- (void)playTickSound
{
    [self playSoundWithName:@"tick"];
}

- (void)playPrivateMessageReceivedSound
{
    [self playSoundWithName:@"privateMessageReceived"];
}

- (void)playSecretFoundSound
{
    [self playSoundWithName:@"secret"];
}

@end
