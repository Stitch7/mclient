//
//  PrivateMessagesCacheUserDefaults.swift
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

import Foundation

final class PrivateMessagesCacheUserDefaults : NSObject, PrivateMessagesCache {

    let userDefaults = UserDefaults.standard

    private let userDefaultsKey = "PrivateMessagesCacheKey"

    private lazy var privateMessages: [String: String] = {
        return userDefaults.object(forKey: userDefaultsKey) as? [String: String] ?? [String: String]()
    }()

    func store(privateMessage: PrivateMessage) {
        privateMessages["\(privateMessage.messageId!)"] = privateMessage.text
        userDefaults.set(privateMessages, forKey: userDefaultsKey)
        userDefaults.synchronize()
    }

    func load(privateMessage: PrivateMessage, completionHandler: (PrivateMessage?) -> Void) {
        if let text = privateMessages["\(privateMessage.messageId!)"] {
            let cachedPM = privateMessage
            cachedPM.text = text
            completionHandler(cachedPM)
        } else {
            completionHandler(nil)
        }
    }
}
