//
//  PrivateMessagesCache.swift
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

import Foundation

typealias PrivateMessage = MCLPrivateMessage

@objc protocol PrivateMessagesCache {
    func store(privateMessage: PrivateMessage)
    func load(privateMessage: PrivateMessage, completionHandler: (PrivateMessage?) -> Void)
}
