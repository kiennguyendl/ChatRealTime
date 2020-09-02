//
//  APIHelper.swift
//  ChatRealtime
//
//  Created by Apple on 7/30/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import FirebaseAuth

class APIHelper {
    static let shared = APIHelper()
    
    let auth = Auth.auth()
    
    func createAccount(email: String, password: String, completion: @escaping((User?, Error?) ->Void)) {
        
        auth.createUser(withEmail: email, password: password, completion: { result, error in
            completion(result?.user, error)
            
        })
    }
    
    func signInWithEmail(email: String, password: String, completion: @escaping((User?, Error?) ->Void)) {
        auth.signIn(withEmail: email, password: password, completion: {result, error in
            completion(result?.user, error)
        })
    }
    
    func signInWithCredential(with credential: AuthCredential, completion: @escaping((User?, Error?) -> Void)) {
         Auth.auth().signIn(with: credential, completion: { result, error in
            completion(result?.user,error)
        })
    }
}
