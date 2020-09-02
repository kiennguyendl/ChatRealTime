//
//  RegisterViewController.swift
//  ChatRealtime
//
//  Created by Apple on 7/29/20.
//  Copyright © 2020 Apple. All rights reserved.
//

//
//  LoginViewController.swift
//  ChatRealtime
//
//  Created by Apple on 7/30/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import SnapKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {

    let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "profile")
        imageView.contentMode = .scaleAspectFit
//        imageView.layer.cornerRadius = imageView.width / 2
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    private let firstNameField: UITextField = {
       let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        
        field.layer.cornerRadius = 8
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        
        field.placeholder = "First Name ..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let lastNameField: UITextField = {
       let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        
        field.layer.cornerRadius = 8
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        
        field.placeholder = "Last Name ..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
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
        return password
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        
        setupUI()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.imageView.layer.cornerRadius = self.imageView.width / 2
    }
    
    private func setupUI() {
        let size = view.width / 3
        
        self.view.addSubview(scrollView)
        scrollView.snp.makeConstraints{ make in
            make.size.equalTo(self.view)
        }
        
        scrollView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(size)
            make.top.equalTo(50)
            make.centerX.equalTo(self.view)
        }
        imageView.layer.cornerRadius = imageView.width / 2
        
        scrollView.addSubview(firstNameField)
        firstNameField.snp.makeConstraints{ make in
            make.top.equalTo(imageView.snp.bottom).offset(40)
            make.left.equalTo(scrollView).offset(20)
            make.right.equalTo(scrollView).offset(-20)
            make.height.equalTo(40)
            make.centerX.equalTo(scrollView)
        }
        
        scrollView.addSubview(lastNameField)
        lastNameField.snp.makeConstraints{ make in
            make.top.equalTo(firstNameField.snp.bottom).offset(30)
            make.left.equalTo(scrollView).offset(20)
            make.right.equalTo(scrollView).offset(-20)
            make.height.equalTo(40)
            make.centerX.equalTo(scrollView)
        }
        
        scrollView.addSubview(emailField)
        emailField.snp.makeConstraints{ make in
            make.top.equalTo(lastNameField.snp.bottom).offset(30)
            make.left.equalTo(scrollView).offset(20)
            make.right.equalTo(scrollView).offset(-20)
            make.height.equalTo(40)
            make.centerX.equalTo(scrollView)
        }
        
        scrollView.addSubview(passwordField)
        passwordField.snp.makeConstraints{ make in
            make.top.equalTo(emailField.snp.bottom).offset(30)
            make.left.equalTo(scrollView).offset(20)
            make.right.equalTo(scrollView).offset(-20)
            make.height.equalTo(40)
            make.centerX.equalTo(scrollView)
        }
        
        scrollView.addSubview(loginButton)
        loginButton.snp.makeConstraints{ make in
            make.top.equalTo(passwordField.snp.bottom).offset(30)
            make.left.equalTo(scrollView).offset(20)
            make.right.equalTo(scrollView).offset(-20)
            make.height.equalTo(40)
            make.centerX.equalTo(scrollView)
        }
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        
        firstNameField.delegate = self
        lastNameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        
        scrollView.isUserInteractionEnabled = true
        imageView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapChangeProfile))
        
        imageView.addGestureRecognizer(gesture)
        
    }
    
    @objc func register() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func tapChangeProfile() {
        presentPhotoPicker()
    }
    
    private func showAlertLoginError(message: String) {
        let alert = UIAlertController(title: "Oop!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func loginTapped() {
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let email = emailField.text, let pass = passwordField.text,
            let firstName = firstNameField.text, let lastName = lastNameField.text,
            !email.isEmpty, !pass.isEmpty,
            !firstName.isEmpty, !lastName.isEmpty
            else {
                showAlertLoginError(message: "Please input all fields to register")
            return
        }
        
        // register account with firebase
        spinner.show(in: view)
        DatabaseManager.shared.userExists(with: email, completion: {[weak self] existed in
            guard let strongSelf = self else {return}
            if existed {
                strongSelf.showAlertLoginError(message: "Account is existing")
            } else {
                APIHelper.shared.createAccount(email: email, password: pass, completion: { user, error in
                    DispatchQueue.main.async {
                        strongSelf.spinner.dismiss()
                    }
                    guard error == nil, let user = user else {return}
                    print("user: \(user)")
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, email: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            guard  let image = strongSelf.imageView.image, let data = image.pngData() else {
                                return
                            }
                            
                            let fileName = chatUser.profilePictureFileName
                            StorageManager.shared.updateProfilePicture(with: data, fileName: fileName, completion: {result in
                                switch(result) {
                                case .success(let downloadURL):
                                    UserDefaults.standard.set(downloadURL, forKey: "profile_picture_url")
                                    break
                                case .failure(let error):
                                    break
                                }
                            })
                        }
                    })
                    strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                })
            }
        })
        
    }

}

extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case firstNameField:
            lastNameField.becomeFirstResponder()
        case lastNameField:
            emailField.becomeFirstResponder()
        case emailField:
            passwordField.becomeFirstResponder()
        default:
            loginTapped()
        }
        
        return true
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoPicker() {
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would yoi like?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take photo", style: .default, handler: { _ in
            self.presentCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: { _ in
            self.presentPhoto()
        }))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true, completion: nil)
    }
    
    func presentPhoto() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.imageView.image = image
            
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
