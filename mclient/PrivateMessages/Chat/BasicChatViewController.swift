//
//  BasicChatViewController.swift
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

import UIKit

extension MessageCollectionViewCell {
    override open func delete(_ sender: Any?) {
        guard
            let collectionView = self.superview as? UICollectionView,
            let indexPath = collectionView.indexPath(for: self)
        else {
            return
        }
        collectionView.delegate?.collectionView?(collectionView, performAction: NSSelectorFromString("delete:"), forItemAt: indexPath, withSender: sender)
    }
}

final class BasicChatViewController: ChatViewController {

    override func configureMessageCollectionView() {
        super.configureMessageCollectionView()
        
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {

        if action == NSSelectorFromString("delete:") {
            return true
        } else {
            return super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        guard action == NSSelectorFromString("delete:") else {
            super.collectionView(collectionView, performAction: action, forItemAt: indexPath, withSender: sender)
            return
        }

        let messageToDelete = self.messageList[indexPath.section]
        let pmToDelete = PrivateMessage()

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        pmToDelete.messageId = formatter.number(from: messageToDelete.messageId)

        MCLPrivateMessageDeleteRequest(client: bag?.httpClient, privateMessage: pmToDelete)?.load { (error, data) in
            self.messageList.remove(at: indexPath.section)
            collectionView.deleteSections([indexPath.section])

            let user = User(id: 0, username: messageToDelete.sender.displayName)
            self.bag?.privateMessagesManager.removePrivateMessage(atRow: indexPath.section, from: user)
        }
    }
}

// MARK: - MessagesDisplayDelegate

extension BasicChatViewController: MessagesDisplayDelegate {
    
    // MARK: - Text Messages
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .darkText : .white
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        return MessageLabel.defaultAttributes
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date, .transitInformation]
    }
    
    // MARK: - All Messages
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? primaryColor : secondaryColor
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(tail, .curved)
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {

        guard let user = User(id: 0, username: message.sender.displayName) else { return }
        avatarView.image = UserAvatarImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30), user: user).image

//        let avatarImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
//                          NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: .medium)]
//        avatarImageView.setImageForName(message.sender.displayName, backgroundColor: .darkGray, circular: true, textAttributes: attributes)
//        avatarImageView.layer.cornerRadius = 0
//        avatarImageView.layer.masksToBounds = false
//        let avatar = Avatar(image: avatarImageView.image, initials: String(message.sender.displayName.first ?? Character("")))
//        avatarView.set(avatar: avatar)
//
//        let urlString = "\(kMServiceBaseURL)/user/\(message.sender.displayName)/avatar.jpg"
//        guard let url = URL(string: urlString) else { return }
//        URLSession.shared.dataTask(with: url) { (data, response, error) in
//            guard error == nil else {
//                print("Failed fetching image \(urlString): \(error.debugDescription)")
//                return
//            }
//
//            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
//                print("Not a proper HTTPURLResponse or statusCode")
//                return
//            }
//
//            DispatchQueue.main.async {
//                if let image = UIImage(data: data!) {
//                    let avatar = Avatar(image: image, initials: String(message.sender.displayName.first ?? Character("")))
//                    avatarView.set(avatar: avatar)
//                }
//            }
//        }.resume()
    }
}

// MARK: - MessagesLayoutDelegate

extension BasicChatViewController: MessagesLayoutDelegate {
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 18
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 20
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }

    func customCellSizeCalculator(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CellSizeCalculator {
        return CellSizeCalculator()
    }
    
}
