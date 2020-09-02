//
//  DatabaseManager.swift
//  ChatRealtime
//
//  Created by Apple on 7/30/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import FirebaseDatabase
import MessageKit

public enum DatabaseError : Error {
    case failedToFetch
    
}

// MARK: - Install
class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(email: String) -> String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        return safeEmail
    }
}

// MARK: - Handle user
extension DatabaseManager {
    
    public func userExists(with email: String, completion: @escaping((Bool) -> Void)) {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            guard let _ = snapshot.value as? String else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    public func insertUser(with user: ChatAppUser, completion: @escaping(Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName,
            //            "email": user.email
            ], withCompletionBlock: {error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                self.database.child("users").observeSingleEvent(of: .value, with:{ snapshot in
                    if var usersCollection = snapshot.value as? [[String: String]] {
                        // append to user dictionary
                        let newElement =
                            [
                                "name": user.firstName + " " + user.lastName,
                                "email": user.safeEmail
                        ]
                        
                        usersCollection.append(newElement)
                        self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                        
                    } else {
                        // create that array
                        let newCollection: [[String: String]] = [
                            [
                                "name": user.firstName + " " + user.lastName,
                                "email": user.safeEmail
                            ]
                        ]
                        self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    }
                })
        })
    }
    
    public func getAllUsers(completion: @escaping(Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: {snaphot in
            guard let value = snaphot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(value))
        })
    }
}

extension DatabaseManager {
    func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.database.child(path).observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(value))
        })
    }
}

// MARK: - Sending message / conversation
extension DatabaseManager {
    func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping(Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            completion(false)
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self, var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch firstMessage.kind {
                
            case .text(let messageText):
                message = messageText
                break
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            let newConversationData: [String : Any] = [
                "id": "conversation_\(firstMessage.messageId)",
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message,
                ]
            ]
            
            let recipient_newConversationData: [String : Any] = [
                "id": "conversation_\(firstMessage.messageId)",
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message,
                ]
            ]
            
            // update recipient user conversation entry
            strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    strongSelf.database.child("\(otherUserEmail)/conversations").setValue([conversations])
                } else {
                    // create
                    strongSelf.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
                
            })
            
            // update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // append to existing conversation
                
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard let strongSelf = self, error == nil else {
                        completion(false)
                        return
                    }
                    
                    let conversationId = "conversation_\(firstMessage.messageId)"
                    strongSelf.finishCreatingConversation(name: name,
                                                          conversationId: conversationId,
                                                          firstMessage: firstMessage,
                                                          completion: completion)
                    
                })
                
            } else {
                // create new conversation if conversation array does not exist
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard let strongSelf = self, error == nil else {
                        completion(false)
                        return
                    }
                    
                    let conversationId = "conversation_\(firstMessage.messageId)"
                    strongSelf.finishCreatingConversation(name: name,
                                                          conversationId: conversationId,
                                                          firstMessage: firstMessage,
                                                          completion: completion)
                })
            }
        })
    }
    
    private func finishCreatingConversation(name: String, conversationId: String, firstMessage: Message, completion: @escaping(Bool) -> Void) {
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        switch firstMessage.kind {
            
        case .text(let messageText):
            message = messageText
            break
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        }
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else  {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(email: email)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.description,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name
        ]
        let value: [String: Any] = [
            "messages":[
                collectionMessage
            ]
        ]
        
        database.child("\(conversationId)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            
            completion(true)
        })
    }
    
    func getAllConversation(forEmail email: String, completion: @escaping(Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                    let name = dictionary["name"] as? String,
                    let otherUserEmail = dictionary["other_user_email"] as? String,
                    let latestMessage = dictionary["latest_message"] as? [String: Any],
                    let sent = latestMessage["date"] as? String,
                    let message = latestMessage["message"] as? String,
                    let isRead = latestMessage["is_read"] as? Bool else {
                        
                        return nil
                }
                
                let latestMessageObject = LatestMessage(date: sent,
                                                        text: message,
                                                        isRead: isRead)
                
                return Conversation(id: conversationId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            })
            
            completion(.success(conversations))
        })
    }
    
    
    func getAllMessagesForConversation(with id: String, completion: @escaping(Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                    let isRead = dictionary["is_read"] as? Bool,
                    let id = dictionary["id"] as? String,
                    let dateStr = dictionary["date"] as? String,
                    let type = dictionary["type"] as? String,
                    let senderEmail = dictionary["sender_email"] as? String,
                    let date = ChatViewController.dateFormatter.date(from: dateStr),
                    let content = dictionary["content"] as? String else {
                        return nil
                }
                
                var kind: MessageKind?
                if type == "photo" {
                    guard let url = URL(string: content), let placeHolder = UIImage(named: "video-placeholder") else { return nil }
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                } else if type == "video" {
                    guard let url = URL(string: content), let placeHolder = UIImage(named: "video-placeholder") else { return nil }
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                }
                else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else { return nil }
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: id,
                               sentDate: date,
                               kind: finalKind)
            })
            
            completion(.success(messages))
        })
    }
    
    // sends a message with target conversation and message
    func sendMessage(to conversationId: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping(Bool) -> Void) {
        // add new messsage to messages
        
        // update sender latest message
        
        // update recipient latest message
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentEmail = DatabaseManager.safeEmail(email: myEmail)
        
        self.database.child("\(conversationId)/messages").observeSingleEvent(of: .value, with: { [weak self]snapshot in
            guard let strongSelf = self, var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            switch newMessage.kind {
                
            case .text(let messageText):
                message = messageText
                break
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrl = mediaItem.url?.absoluteString {
                    message = targetUrl
                }
                break
            case .video(let mediaItem):
                if let targetUrl = mediaItem.url?.absoluteString {
                    message = targetUrl
                }
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            guard let email = UserDefaults.standard.value(forKey: "email") as? String else  {
                completion(false)
                return
            }
            
            let currentUserEmail = DatabaseManager.safeEmail(email: email)
            
            let messengeEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.description,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]
            
            currentMessages.append(messengeEntry)
            
            strongSelf.database.child("\(conversationId)/messages").setValue( currentMessages, withCompletionBlock: { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    guard var currentConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "message": message,
                        "is_read": false
                    ]
                    
                    var targetConversation: [String: Any]?
                    
                    var position = 0
                    for conversationDictionary in currentConversations {
                        if let currentId = conversationDictionary["id"] as? String, currentId == conversationId {
                           targetConversation = conversationDictionary
                            break
                        }
                        position += 1
                    }
                    
                    targetConversation?["latest_message"] = updatedValue
                    
                    guard let _targetConversation = targetConversation else {
                        completion(false)
                        return
                    }
                    currentConversations[position] = _targetConversation
                    
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(currentConversations, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        // update latest message for recipient user
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }
                            
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "message": message,
                                "is_read": false
                            ]
                            
                            var targetConversation: [String: Any]?
                            
                            var position = 0
                            for conversationDictionary in otherUserConversations {
                                if let currentId = conversationDictionary["id"] as? String, currentId == conversationId {
                                   targetConversation = conversationDictionary
                                    break
                                }
                                position += 1
                            }
                            
                            targetConversation?["latest_message"] = updatedValue
                            
                            guard let _targetConversation = targetConversation else {
                                completion(false)
                                return
                            }
                            otherUserConversations[position] = _targetConversation
                            
                            strongSelf.database.child("\(currentEmail)/conversations").setValue(otherUserConversations, withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                
                                completion(true)
                            })
                        })
                    })
                })
            })
        })
    }
    
    public func deleteConversation(conversationId: String, completion: @escaping(Bool) -> Void) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: email)
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if var conversations = snapshot.value as? [[String: Any]] {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String, id == conversationId {
                        break
                    }
                    
                    positionToRemove += 1
                }
                
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        print("Fail to delete conversation")
                        return
                    }
                    
                    print("Deleted conversation")
                    completion(true)
                })
                
            }
        })
    }
}

// MARK: - Structer
struct ChatAppUser {
    var firstName: String
    var lastName: String
    var email: String
    
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
    
    var safeEmail: String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        return safeEmail
    }
}
