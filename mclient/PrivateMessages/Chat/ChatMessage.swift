//
//  ChatMessage.swift
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//


import Foundation
//import CoreLocation
//import MessageKit

private struct ImageMediaItem: MediaItem {

    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize

    init(image: UIImage) {
        self.image = image
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
    }

}

enum ChatMessageType: String {
    case inbox = "inbox"
    case outbox = "outbox"
}

struct ChatMessage: MessageType {

    var type: ChatMessageType
    var messageId: String
    var sender: Sender
    var subject: String
    var sentDate: Date
    var kind: MessageKind

    private init(type: ChatMessageType, kind: MessageKind, sender: Sender, subject: String, messageId: String, date: Date) {
        self.type = type
        self.kind = kind
        self.sender = sender
        self.subject = subject
        self.messageId = messageId
        self.sentDate = date
    }

    init(type: ChatMessageType, text: String, sender: Sender, subject: String, messageId: String, date: Date) {
        self.init(type: type, kind: .text(text), sender: sender, subject: subject, messageId: messageId, date: date)
    }

    init(type: ChatMessageType, image: UIImage, sender: Sender, subject: String, messageId: String, date: Date) {
        let mediaItem = ImageMediaItem(image: image)
        self.init(type: type, kind: .photo(mediaItem), sender: sender, subject: subject, messageId: messageId, date: date)
    }
}
