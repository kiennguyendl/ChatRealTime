//
//  ViewController.swift
//  ChatRealtime
//
//  Created by Apple on 7/29/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import FirebaseAuth
import SnapKit
import JGProgressHUD

class ConversationViewController: UIViewController {
    
    let spinner = JGProgressHUD(style: .dark)
    private var conversations = [Conversation]()
    private var loginObserver: NSObjectProtocol?
    
    private let tableview: UITableView = {
        let tableview = UITableView()
        tableview.isHidden = true
        tableview.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        tableview.tableFooterView = UIView()
        return tableview
    }()
    
    private let noConversationLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    
    func validateAuth() {
        
        if Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        }
    }
    
    func setupUI() {
        self.view.addSubview(tableview)
        self.view.addSubview(noConversationLabel)
        setupTableView()
        fetchConversations()
        startListeningForConversations()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginGoogleNotification, object: nil, queue: .main, using: {[weak self]_ in
        guard let strongSelf = self else {return}
            strongSelf.startListeningForConversations()
        })
        // add tableview contraints
        
        tableview.snp.makeConstraints({make in
            make.size.equalTo(self.view)
        })
        
        noConversationLabel.snp.makeConstraints({make in
            make.size.equalTo(self.view)
        })
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTappedComposeButton))
    }
    
    func setupTableView() {
        tableview.delegate = self
        tableview.dataSource = self
        
    }
    
    private func fetchConversations() {
        tableview.isHidden = false
    }
    
    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {return}
        let safeEmail = DatabaseManager.safeEmail(email: email)
        print("start loading conversations ...")
        DatabaseManager.shared.getAllConversation(forEmail: safeEmail, completion: { [weak self] result in
            guard let strongSelf = self else { return }
            
            if let observer = strongSelf.loginObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            
            switch result {
            case .success(let conversations):
                guard conversations.count > 0 else {
                    return
                }
                print("successfully got conversations")
                strongSelf.conversations = conversations
                DispatchQueue.main.async {
                    strongSelf.tableview.reloadData()
                }
            case .failure(let _):
                print("fail to get conversations")
            }
        })
    }
    
    @objc private func didTappedComposeButton() {
        let vc = NewConversationViewController()
        vc.completion = {[weak self] result in
            guard  let strongSelf = self else {
                return
            }
            print("\(result)")
            strongSelf.createNewConversation(result: result)
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true, completion: nil)
    }
    
    private func createNewConversation(result: SearchResult) {
        let name = result.name
        let email = result.email
        
        let vc = ChatViewController(with: email, id: nil)
        vc.title = name
        vc.isNewConversation = true
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        let model = conversations[indexPath.row]
        cell.configure(with: model)
//        cell.textLabel?.text = "Hello world!"
//        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = conversations[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let conversationId = conversations[indexPath.row].id
            
            tableView.beginUpdates()
            DatabaseManager.shared.deleteConversation(conversationId: conversationId, completion: {[weak self] success in
                guard let strongSelf = self else { return }
                
                if success {
                    strongSelf.conversations.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .left)
                } else {
                    let alert = UIAlertController(title: "Oop!", message: "An error occurred while deleting data", preferredStyle: .alert)
                    strongSelf.present(alert, animated: true, completion: nil)
                }
            })
            
            tableView.endUpdates()
        }
    }
}
