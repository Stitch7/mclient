//
//  ChatViewController.swift
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

import Foundation
import UIKit
//import MessageKit
//import MessageInputBar

let primaryColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1) // grey
let secondaryColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1) // green

class ChatViewController: MessagesViewController, MessagesDataSource {

    var privateMessagesCache: PrivateMessagesCache?
    var existingprivateMessages = [PrivateMessage]()

    var observation : NSKeyValueObservation?

    @objc var bag: MCLDependencyBag? {
        didSet {
            self.privateMessagesCache = self.bag?.privateMessagesManager.privateMessagesCache
        }
    }

    @objc var conversation: MCLPrivateMessageConversation? {
        didSet {
            title = conversation?.username
        }
    }

    var queue: OperationQueue =  {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "mclient.private-message-loading-queue"
        return queue
    }()

    // semaphore with count equal to zero is useful for synchronizing completion of work, in our case the renewal of auth token
    let semaphore = DispatchSemaphore(value: 0)

    lazy var me: Sender = {
        let name = bag?.loginManager.username ?? ""
        return Sender(id: name, displayName: name)
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var messageList: [ChatMessage] = []

    let refreshControl = UIRefreshControl()

    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMessageCollectionView()
        configureMessageInputBar()

        observation = queue.observe(\.operationCount, options: [.new]) { [unowned self] (queue, change) in
            guard let newValue = change.newValue, newValue == 0 else { return }

            self.addToChat(messages: self.existingprivateMessages.reversed())
            self.observation = nil
        }
        loadExistingMessages()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if #available(iOS 11.0, *) {
            bag?.router.masterNavigationController.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        MockSocket.shared.disconnect()
    }

    @objc func profileButtonPressed(sender: UIBarButtonItem) {
        guard let username = conversation?.username else { return }
        let user = MCLUser()
        user.username = username
        let profileVC = self.bag?.router?.modalToProfile(from: user)
        profileVC?.showPrivateMessagesButton = false
    }

    private func addToChat(messages: [PrivateMessage]) {
        guard let conversation = self.conversation else { return }

        let chatMessages = messages.map { (message) -> ChatMessage in
            let type = ChatMessageType(rawValue: message.type) ?? .inbox
            let sender = message.type == "inbox" ? Sender(id: conversation.username, displayName: conversation.username) : self.me
            return ChatMessage(type: type,
                               text: message.text,
                               sender: sender,
                               subject: message.subject,
                               messageId: "String(message.messageId ?? 0)", // TODO
                               date: message.date)
        }

        DispatchQueue.main.async {
            self.messageList.insert(contentsOf: chatMessages, at: 0)
//            self.messagesCollectionView.reloadDataAndKeepOffset()
            self.messagesCollectionView.reloadData()
            self.messagesCollectionView.scrollToBottom()

            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
        }
    }

    @objc func loadExistingMessages() {
        guard let conversation = self.conversation, let messages = conversation.messages else {
            return
        }

        existingprivateMessages = [PrivateMessage]()

        for message in messages {
            guard let message = message as? PrivateMessage else { continue }
            guard let client = self.bag?.httpClient else { return }

            let operation = createOperation(message: message, client: client)

            if let lastOperation = queue.operations.last {
                operation.addDependency(lastOperation)
//                print("\(operation.name!) should finish after \(operation.dependencies.first!.name!)")
            }

            queue.addOperation(operation)
        }
    }

    func createOperation(message: PrivateMessage, client: MCLHTTPClient) -> BlockOperation {
        return BlockOperation {
//            print("Operation #\(message.messageId ?? 0) started")
            self.privateMessagesCache?.load(privateMessage: message) { (cachedMessage) in
                if let message = cachedMessage {
                    self.existingprivateMessages.append(message)
//                    self.addToChat(message: message)
//                    print("Operation #\(message.messageId ?? 0) finished from CACHE")
                } else {
                    MCLPrivateMessageRequest(client: client, privateMessage: message)?.load(completionHandler: { (err, data) in
                        if let arr = data as? Array<Dictionary<String, String>>,
                            let text = arr.first?["text"]
                        {
                            message.isRead = true
                            message.text = text
//                            self.addToChat(message: message)
                            self.existingprivateMessages.append(message)
                            self.privateMessagesCache?.store(privateMessage: message)
//                            print("Operation #\(message.messageId ?? 0) finished from REQUEST")
                        }

                        self.semaphore.signal()
                    })

                    _ = self.semaphore.wait(timeout: .distantFuture)
                }
            }
        }
    }

    @objc func refresh() {

    }

    func configureMessageCollectionView() {
        messagesCollectionView.backgroundColor = bag?.themeManager.currentTheme.backgroundColor()

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self

        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false

        messagesCollectionView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    func configureMessageInputBar() {
        messageInputBar.delegate = self
//        messageInputBar.inputTextView.tintColor = primaryColor
        messageInputBar.sendButton.tintColor = primaryColor
        messageInputBar.backgroundView.backgroundColor = bag?.themeManager.currentTheme.tableViewCellBackgroundColor()
        messageInputBar.inputTextView.keyboardAppearance = bag?.themeManager.currentTheme.isDark() ?? true ? .dark : .light
    }

    // MARK: - Helpers

    func insertMessage(_ message: ChatMessage) {
        messageList.append(message)
        // Reload last section to update header/footer labels and insert a new one
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([messageList.count - 1])
            if messageList.count >= 2 {
                messagesCollectionView.reloadSections([messageList.count - 2])
            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }

            let newPm = MCLPrivateMessage()
            if case .text(let textVal) = message.kind {
                print(textVal)
                newPm.text = textVal
            }
            MCLPrivateMessageSendRequest(client: self?.bag?.httpClient, privateMessage: newPm)?.load(completionHandler: { (error, data) in
//                guard let arr = data as? Array<Dictionary<String, String>>, let text = arr.first?["text"] else { return }
            })
        })
    }

    func isLastSectionVisible() -> Bool {
        guard !messageList.isEmpty else { return false }

        let lastIndexPath = IndexPath(item: 0, section: messageList.count - 1)
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }

    // MARK: - MessagesDataSource

    func currentSender() -> Sender {
        return me
    }

    func isFromCurrentSender(message: MessageType) -> Bool {
        guard let mockMessage = message as? ChatMessage else { return false }
        return mockMessage.type == .outbox
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            let attrs = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                         NSAttributedString.Key.foregroundColor: UIColor.darkGray]
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: attrs)
        }
        return nil
    }

    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        guard let chatMessage = message as? ChatMessage else { return nil }

        let attr = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1),
                    NSAttributedString.Key.foregroundColor: bag?.themeManager.currentTheme.textColor() ?? UIColor.black]
        return NSAttributedString(string: chatMessage.subject, attributes: attr)
    }

    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateString = formatter.string(from: message.sentDate)
        let attr = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2),
                    NSAttributedString.Key.foregroundColor: bag?.themeManager.currentTheme.textColor() ?? UIColor.black]
        return NSAttributedString(string: dateString, attributes: attr)
    }

}

// MARK: - MessageCellDelegate

extension ChatViewController: MessageCellDelegate {

    func didTapAvatar(in cell: MessageCollectionViewCell) {
        guard
            let indexPath = messagesCollectionView.indexPath(for: cell),
            let messagesDataSource = messagesCollectionView.messagesDataSource
        else { return }

        let user = MCLUser()
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        user.username = message.sender.displayName
        let profileVC = self.bag?.router?.modalToProfile(from: user)
        profileVC?.showPrivateMessagesButton = false
    }

    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
    }

    func didTapCellTopLabel(in cell: MessageCollectionViewCell) {
        print("Top cell label tapped")
    }

    func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
        print("Top message label tapped")
    }

    func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom label tapped")
    }

    func didTapAccessoryView(in cell: MessageCollectionViewCell) {
        print("Accessory view tapped")
    }

}

// MARK: - MessageLabelDelegate

extension ChatViewController: MessageLabelDelegate {

    func didSelectAddress(_ addressComponents: [String: String]) {
        print("Address Selected: \(addressComponents)")
    }

    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }

    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }

    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }

    func didSelectTransitInformation(_ transitInformation: [String: String]) {
        print("TransitInformation Selected: \(transitInformation)")
    }

}

// MARK: - MessageInputBarDelegate

extension ChatViewController: MessageInputBarDelegate {

    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        for component in inputBar.inputTextView.components {

            let messageId = UUID().uuidString
            let currentDate = Date()
            if let str = component as? String {
                let message = ChatMessage(type: .outbox, text: str, sender: me, subject: String(str.prefix(10)), messageId: messageId, date: currentDate)
                insertMessage(message)
            } else if let img = component as? UIImage {
                let message = ChatMessage(type: .outbox, image: img, sender: me, subject: "", messageId: messageId, date: currentDate)
                insertMessage(message)
            }
        }
        inputBar.inputTextView.text = ""
        messagesCollectionView.scrollToBottom(animated: true)
    }

}
