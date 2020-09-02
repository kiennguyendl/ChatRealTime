//
//  ChatViewController.swift
//  ChatRealtime
//
//  Created by Apple on 8/2/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit

class ChatViewController: MessagesViewController {
    
    // MARK: Properties
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    public let otherUserEmail: String
    private let conversationId: String?
    public var isNewConversation = false
    
    private var messages = [Message]()
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: email)
        return Sender(photoURL: "",
                      senderId:  safeEmail ,
                      displayName: "Me")
    }
    
    init(with email: String, id: String?) {
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Life cicrle
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.messagesCollectionView.contentInset = UIEdgeInsets(top: isIphoneX() ? 64 : 44, left: 0, bottom: 0, right: 0)
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messageCellDelegate = self
        setupInputButton()
        
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside({ [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.presentInputActionSheet()
        })
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let actionController = UIAlertController(title: "Attach Media",
                                                 message: "What would you like to attach?",
                                                 preferredStyle: .actionSheet)
        actionController.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.presentPhotoActionSheet()
        }))
        
        actionController.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.presentVideoActionSheet()
        }))
        
        actionController.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.presentAudoActionSheet()
        }))
        
        actionController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        
        present(actionController, animated: true, completion: nil)
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        
        if let conversationId = conversationId {
            listenForMessage(conversationId: conversationId, shouldScrollToBottom: true)
        }
    }
    
    
    private func listenForMessage(conversationId: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: conversationId, completion: { [weak self] result in
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                
                strongSelf.messages = messages
                DispatchQueue.main.async {
                    strongSelf.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom {
                        strongSelf.messagesCollectionView.scrollToBottom()
                    }
                }
                
                break
            case .failure(let error):
                print("failed to load all messages: \(error.localizedDescription)")
            }
        })
    }
}

// MARK: ActionSheet Actions

extension ChatViewController {
    // present Photo
    private func presentPhotoActionSheet() {
        let actionController = UIAlertController(title: "Attach Photo",
                                                 message: "Where would you like to attach a photo from?",
                                                 preferredStyle: .actionSheet)
        actionController.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            guard let strongSelf = self else { return }
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            
            strongSelf.present(picker, animated: true, completion: nil)
        }))
        
        actionController.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            guard let strongSelf = self else { return }
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            
            strongSelf.present(picker, animated: true, completion: nil)
        }))
        
        
        actionController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionController, animated: true, completion: nil)
    }
    
    private func presentVideoActionSheet() {
        let actionController = UIAlertController(title: "Attach Video",
                                                 message: "Where would you like to attach a video from?",
                                                 preferredStyle: .actionSheet)
        actionController.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            guard let strongSelf = self else { return }
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            
            strongSelf.present(picker, animated: true, completion: nil)
        }))
        
        actionController.addAction(UIAlertAction(title: "Video Library", style: .default, handler: { [weak self] _ in
            guard let strongSelf = self else { return }
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            
            strongSelf.present(picker, animated: true, completion: nil)
        }))
        
        
        actionController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionController, animated: true, completion: nil)
    }
    
    private func presentAudoActionSheet() {
        
    }
}

// MARK: Image picker
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let conversationId = conversationId,
            let name = self.title,
            let selfSender = self.selfSender else {
                return
        }
        
        let messageId = createMessageId()
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            
            // upload image
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else { return }
                switch result {
                case .success(let urlString):
                    guard let url = URL(string: urlString), let placeHolder = UIImage(systemName: "plus") else { return }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeHolder, size: .zero)
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: { success in
                        if success {
                            print("sent photo success")
                        } else {
                            print("failed to send photo")
                        }
                    })
                case .failure(let error):
                    print("can not upload photo: \(error.localizedDescription)")
                }
            })
        } else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "video_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            print("video url: \(videoUrl)")
            
            do {
                if #available(iOS 13, *) {
                    let urlString = videoUrl.relativeString
                    let urlSlices = urlString.split(separator: ".")
                    let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                    let targetURL = tempDirectoryURL.appendingPathComponent(String(urlSlices[1])).appendingPathExtension(String(urlSlices[2]))
                    try FileManager.default.copyItem(at: videoUrl, to: targetURL)
                    
                    uploadVideo(with: targetURL, selfSender: selfSender, fileName: fileName, messageId: messageId, name: name, conversationId: conversationId)
                } else {
                    uploadVideo(with: videoUrl, selfSender: selfSender, fileName: fileName, messageId: messageId, name: name, conversationId: conversationId)
                }
            } catch let error {
                print(error.localizedDescription)
            }
            
        }
        
    }
    
    private func uploadVideo(with videoUrl: URL, selfSender: Sender, fileName: String, messageId: String, name: String, conversationId: String) {
        // upload video
        StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName, completion: { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let urlString):
                guard let url = URL(string: urlString), let placeHolder = UIImage(systemName: "plus") else { return }
                
                let media = Media(url: url, image: nil, placeholderImage: placeHolder, size: .zero)
                let message = Message(sender: selfSender,
                                      messageId: messageId,
                                      sentDate: Date(),
                                      kind: .video(media))
                
                
                DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: { success in
                    if success {
                        print("sent video success")
                    } else {
                        print("failed to send video")
                    }
                })
            case .failure(let error):
                print("can not upload video: \(error.localizedDescription)")
            }
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = self.selfSender else {
            return
        }
        
        print("Sending text: \(text)")
        // send message
        if isNewConversation {
            // create new conversation
            let message = Message(sender: selfSender,
                                  messageId: createMessageId(),
                                  sentDate: Date(),
                                  kind: .text(text))
            DatabaseManager.shared.createNewConversation(with: otherUserEmail,
                                                         name: self.title ?? "User",
                                                         firstMessage: message,
                                                         completion: { [weak self] success in
                                                            
                                                            guard let strongSelf = self else { return }
                                                            if success {
                                                                strongSelf.isNewConversation = false
                                                            } else {
                                                                
                                                            }
            })
        } else {
            // append to existing conversation
            let message = Message(sender: selfSender,
                                  messageId: createMessageId(),
                                  sentDate: Date(),
                                  kind: .text(text))
            
            guard let conversationId = conversationId, let name = self.title else { return }
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: message, completion: { success in
                if success {
                    print("send success")
                } else {
                    print("send fail")
                }
            })
        }
    }
    
    private func createMessageId() -> String {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return ""
        }
        
        let safeCurrentUserEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentUserEmail)_\(dateString)"
        return newIdentifier
    }
}

// MARK: Messages Delegate + Datasource
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            
            imageView.sd_setImage(with: imageURL, completed: nil)
        default:
            break
        }
    }
    
}

extension ChatViewController: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            
            let vc = PhotoViewerViewController(url: imageURL)
            self.navigationController?.pushViewController(vc, animated: true)
            
        case .video(let media):
            guard let imageURL = media.url else {
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: imageURL)
            present(vc, animated: true, completion: nil)
        default:
            break
        }
    }
}
