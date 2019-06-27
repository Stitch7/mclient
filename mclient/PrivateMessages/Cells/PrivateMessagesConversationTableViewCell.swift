//
//  PrivateMessagesConversationTableViewCell.swift
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

class PrivateMessagesConversationTableViewCell: UITableViewCell {

    @objc static let Identifier = "ConversationCell"

    @IBOutlet weak var avatarImageView: UserAvatarImageView!
    @IBOutlet weak var readSymbolView: MCLReadSymbolView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var lastMessageDateLabel: UILabel!
    @IBOutlet weak var lastMessageTextLabel: UILabel!

    @IBOutlet weak var arrowForwardImageView: UIImageView!
    @objc var dateFormatter: DateFormatter?

    @objc var bag: MCLDependencyBag? {
        didSet {
            guard let bag = bag else { return }

            let theme = bag.themeManager.currentTheme

            textLabel?.textColor = theme?.textColor()
            detailTextLabel?.textColor = theme?.textColor()

            let backgroundView = UIView(frame: frame)
            backgroundView.backgroundColor = theme?.tableViewCellSelectedBackgroundColor()
            selectedBackgroundView = backgroundView;
        }
    }

    @objc var conversation: MCLPrivateMessageConversation? {
        didSet {
            guard let conversation = self.conversation else { return }

            if let user = User(id: 0, username: conversation.username) {
                avatarImageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
                avatarImageView.user = user
            }

            usernameLabel.text = conversation.username
            lastMessageDateLabel.text = dateFormatter?.string(from: conversation.lastMessage.date)
            lastMessageTextLabel.text = conversation.lastMessage.subject

            if conversation.hasUnreadMessages() {
                readSymbolView.color = tintColor
                lastMessageTextLabel.font = UIFont.boldSystemFont(ofSize: lastMessageTextLabel.font.pointSize)
            } else {
                readSymbolView.color = bag?.themeManager.currentTheme.tableViewCellBackgroundColor()
                lastMessageTextLabel.font = UIFont.systemFont(ofSize: lastMessageTextLabel.font.pointSize)
            }

            lastMessageDateLabel.textColor = .gray
            arrowForwardImageView.tintColor = .lightGray
            arrowForwardImageView.image = arrowForwardImageView.image?.withRenderingMode(.alwaysTemplate)

            bag?.privateMessagesManager.privateMessagesCache.load(privateMessage: conversation.lastMessage) { (cachedMessage) in
                if let message = cachedMessage {
                    lastMessageTextLabel.text = message.text
                }
            }
        }
    }
}
