//
//  MCLRouter+Tetromino.swift
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

import TetrominoTouchKit

public extension MCLRouter {
    @objc @discardableResult func modalToGame() -> UINavigationController {
        if !bag.settings.isSettingActivated(MCLSettingSecretFound) {
            bag.soundEffectPlayer.playSecretFoundSound()
            bag.settings.setBool(true, forSetting: MCLSettingSecretFound)
        }

        let gameVC = TetrominoTouchKit().makeGameController()
        masterNavigationController.present(gameVC, animated: true)

        return gameVC
    }
}

