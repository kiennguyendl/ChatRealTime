//
//  LoginViewController.swift
//  ChatRealtime
//
//  Created by Apple on 7/30/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    private let spinner = JGProgressHUD(style: .dark)
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        
        field.layer.cornerRadius = 8
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        
        field.placeholder = "Email Address ..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isUserInteractionEnabled = true
        return field
    }()
    
    private let passwordField: UITextField = {
        let password = UITextField()
        password.autocapitalizationType = .none
        password.autocorrectionType = .no
        password.returnKeyType = .done
        
        password.layer.cornerRadius = 8
        password.layer.borderWidth = 1
        password.layer.borderColor = UIColor.lightGray.cgColor
        
        password.placeholder = "Password ..."
        password.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        password.leftViewMode = .always
        password.backgroundColor = .white
        password.isSecureTextEntry = true
        password.isUserInteractionEnabled = true
        return password
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        return stackView
    }()
    
    private let loginFBButton: FBLoginButton = {
        let fbLoginBtn = FBLoginButton()
        fbLoginBtn.layer.cornerRadius = 8
        fbLoginBtn.layer.masksToBounds = true
        fbLoginBtn.permissions = ["email,public_profile"]
        let buttonText = NSAttributedString(string: "Facebook")
        fbLoginBtn.setAttributedTitle(buttonText, for: .normal)
        
        for const in fbLoginBtn.constraints{
            if const.firstAttribute == NSLayoutConstraint.Attribute.height && const.constant == 28{
                fbLoginBtn.removeConstraint(const)
            }
        }
        
        return fbLoginBtn
    }()
    
    private let googleLoginBtn: GIDSignInButton = {
        let button = GIDSignInButton()
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
    
    
    private var loginObserver: NSObjectProtocol?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginGoogleNotification, object: nil, queue: .main, using: {[weak self]_ in
            guard let strongSelf = self else {return}
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
        
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        title = "Login"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .plain, target: self, action: #selector(register))
        
        setupUI()
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    private func setupUI() {
        let size = view.width / 3
        
        self.view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(stackView)
        stackView.addSubview(loginFBButton)
        stackView.addSubview(googleLoginBtn)
        
        // add scroll view
        scrollView.snp.makeConstraints{ make in
            make.size.equalTo(self.view)
        }
        
        // add imageview
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(size)
            make.top.equalTo(50)
            make.centerX.equalTo(self.view)
        }
        
        // add email textfield
        emailField.snp.makeConstraints{ make in
            make.top.equalTo(imageView.snp.bottom).offset(40)
            make.left.equalTo(scrollView).offset(20)
            make.right.equalTo(scrollView).offset(-20)
            make.height.equalTo(40)
            make.centerX.equalTo(scrollView)
        }
        emailField.delegate = self
        
        // add password textfield
        passwordField.snp.makeConstraints{ make in
            make.top.equalTo(emailField.snp.bottom).offset(30)
            make.left.equalTo(scrollView).offset(20)
            make.right.equalTo(scrollView).offset(-20)
            make.height.equalTo(40)
            make.centerX.equalTo(scrollView)
        }
        passwordField.delegate = self
        
        // add email login button
        loginButton.snp.makeConstraints{ make in
            make.top.equalTo(passwordField.snp.bottom).offset(30)
            make.left.equalTo(scrollView).offset(20)
            make.right.equalTo(scrollView).offset(-20)
            make.height.equalTo(40)
            make.centerX.equalTo(scrollView)
        }
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        
        // add stack view
        stackView.snp.makeConstraints{ make in
            make.top.equalTo(loginButton.snp.bottom).offset(30)
            make.left.equalTo(scrollView).offset(20)
            make.right.equalTo(scrollView).offset(-20)
            make.height.equalTo(40)
            make.centerX.equalTo(scrollView)
        }
        
        loginFBButton.delegate = self
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        //         add facebook login button
        loginFBButton.snp.makeConstraints{make in
            make.top.equalTo(stackView.snp.top)
            make.bottom.equalTo(stackView.snp.bottom)
            make.left.equalTo(stackView.left)
            make.width.equalTo(stackView.frame.size.width / 2 - 10)
        }
        
        // add google login button
        googleLoginBtn.snp.makeConstraints{make in
            make.top.equalTo(stackView.snp.top)
            make.bottom.equalTo(stackView.snp.bottom)
            make.right.equalTo(stackView.right)
            make.width.equalTo(stackView.frame.size.width / 2 - 10)
        }
    }
    @objc func register() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showAlertLoginError() {
        let alert = UIAlertController(title: "Oop!", message: "please enter all information to login", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func loginTapped() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let email = emailField.text, let pass = passwordField.text, !email.isEmpty, !pass.isEmpty else {
            showAlertLoginError()
            return
        }
        
        spinner.show(in: view)
        // login with firebase
        APIHelper.shared.signInWithEmail(email: email, password: pass, completion: {[weak self] user, error in
            guard let strongSelf = self else {return}
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            
            guard let user = user, error == nil else {return}
            let safeEmail = DatabaseManager.safeEmail(email: email)
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result {
                case .success(let value):
                    guard let userData = value as? [String: Any],
                        let firstName = userData["first_name"] as? String,
                        let lastName = userData["last_name"] as? String else {
                        return
                    }
                    
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("fail to fetch user info: \(error.localizedDescription)")
                }
            })
            UserDefaults.standard.set(email, forKey: "email")

            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginTapped()
        }
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    
}

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            return
        }
        
        let facebookRequest = GraphRequest(graphPath: "me", parameters: ["fields": "email, first_name, last_name, picture.type(large)"],tokenString: token, version: nil, httpMethod: .get)
        facebookRequest.start(completionHandler: {_, result, error in
            guard let result = result as? [String: Any], error == nil else {return}
            
            guard let firstName = result["first_name"] as? String,
                let lastName = result["last_name"] as? String,
                let email = result["email"] as? String,
                let picture = result["picture"] as? [String: Any?],
                let data = picture["data"] as? [String: Any?],
                let pictureURL = data["url"] as? String
                else {return}
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            DatabaseManager.shared.userExists(with: email, completion: {exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, email: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            guard let url = URL(string: pictureURL) else {
                                print("Failed to insert user")
                                return
                            }
                            
                            let dataTask = URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
                                guard let data = data else {

                                    return
                                }

                                //upload image
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.updateProfilePicture(with: data, fileName: fileName, completion: {result in
                                    switch(result) {
                                    case .success(let downloadURL):
                                        UserDefaults.standard.set(downloadURL, forKey: "profile_picture_url")
                                    case .failure(let error):
                                        print("Failed to upload \(error.localizedDescription)")
                                    }
                                })
                            })
                            dataTask.resume()
                        }
                    })
                }
            })
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            APIHelper.shared.signInWithCredential(with: credential, completion: {[weak self] result, error in
                guard let strongSelf = self else {return}
                
                //                guard let result = result, error == nil else {return}
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
    }
}
