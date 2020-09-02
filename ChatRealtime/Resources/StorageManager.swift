//
//  StorageManager.swift
//  ChatRealtime
//
//  Created by Apple on 8/4/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import FirebaseStorage

public enum storageEnum: Error {
    case failedToUp
    case failedToGetDownload
}

final class StorageManager {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    public func updateProfilePicture(with data: Data,
                                     fileName: String,
                                     completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: {[weak self] metadata, error in
            guard let strongSelf = self, error == nil else {
                completion(.failure(storageEnum.failedToUp))
                return
            }
            
            strongSelf.storage.child("images/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else {
                    completion(.failure(storageEnum.failedToGetDownload))
                    return
                }
                
                let urlString = url.absoluteString
                completion(.success(urlString))
            })
        })
    }
    
    public func uploadMessagePhoto(with data: Data,
                                     fileName: String,
                                     completion: @escaping UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: {[weak self] metadata, error in
            guard let strongSelf = self, error == nil else {
                completion(.failure(storageEnum.failedToUp))
                return
            }
            
            strongSelf.storage.child("message_images/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else {
                    completion(.failure(storageEnum.failedToGetDownload))
                    return
                }
                
                let urlString = url.absoluteString
                completion(.success(urlString))
            })
        })
    }
    
    public func uploadMessageVideo(with fileURL: URL,
                                     fileName: String,
                                     completion: @escaping UploadPictureCompletion) {
        storage.child("message_videos/\(fileName)").putFile(from: fileURL, metadata: nil, completion: {[weak self] metadata, error in
            guard let strongSelf = self, error == nil else {
                completion(.failure(storageEnum.failedToUp))
                return
            }
            
            strongSelf.storage.child("message_videos/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else {
                    completion(.failure(storageEnum.failedToGetDownload))
                    return
                }
                
                let urlString = url.absoluteString
                completion(.success(urlString))
            })
        })
    }
    
    public func downloadURL(for path: String, completion: @escaping(Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(storageEnum.failedToGetDownload))
                return
            }
            
            completion(.success(url))
        })
    }
    
    
}
