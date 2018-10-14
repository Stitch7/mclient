//
//  MCLRouter+Tetromino.swift
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

//import TetrominoTouchKit

public extension MCLRouter {
    @objc @discardableResult public func modalToGame() -> UINavigationController {
//        let gameVC = TetrominoTouch().makeGameController(bounds: UIScreen.main.bounds)
        let gameVC = UINavigationController()
        masterNavigationController.present(gameVC, animated: true)

        return gameVC
    }
}

