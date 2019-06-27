//
//  MockSocket.swift
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

import UIKit
//import MessageKit

final class MockSocket {
    
    static var shared = MockSocket()
    
    private var timer: Timer?
    
    private var queuedMessage: ChatMessage?
    
    private var onNewMessageCode: ((ChatMessage) -> Void)?
    
    private var onTypingStatusCode: (() -> Void)?
    
    private var connectedUsers: [Sender] = []
    
    private init() {}
    
    @discardableResult
    func connect(with senders: [Sender]) -> Self {
        disconnect()
        connectedUsers = senders
        timer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: true)
        return self
    }
    
    @discardableResult
    func disconnect() -> Self {
        timer?.invalidate()
        timer = nil
        onTypingStatusCode = nil
        onNewMessageCode = nil
        return self
    }
    
    @discardableResult
    func onNewMessage(code: @escaping (ChatMessage) -> Void) -> Self {
        onNewMessageCode = code
        return self
    }
    
    @discardableResult
    func onTypingStatus(code: @escaping () -> Void) -> Self {
        onTypingStatusCode = code
        return self
    }
    
    @objc
    private func handleTimer() {
        if let message = queuedMessage {
            onNewMessageCode?(message)
            queuedMessage = nil
        } else {
//            let sender = arc4random_uniform(1) % 2 == 0 ? connectedUsers.first! : connectedUsers.last!
//            SampleData.shared.getMessages(count: 1, allowedSenders: [sender]) { (message) in
//                queuedMessage = message.first
//            }
            onTypingStatusCode?()
        }
    }
    
}
