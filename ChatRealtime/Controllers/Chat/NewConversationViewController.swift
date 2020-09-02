//
//  NewConversationViewController.swift
//  ChatRealtime
//
//  Created by Apple on 7/29/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {

    let spinner = JGProgressHUD(style: .dark)
    public var completion:((SearchResult) -> (Void))?
    private var users = [[String: String]]()
    private var hasFetched = false
    private var results = [SearchResult]()
    
    let searchbar: UISearchBar = {
        let searchbar = UISearchBar()
        searchbar.placeholder = "Search for users ..."
        
        return searchbar
    }()
    
    let tableView: UITableView = {
        let table = UITableView()
        table.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        table.tableFooterView = UIView()
        table.isHidden = true
        return table
    }()
    
    private let noResultLabel: UILabel = {
       let label = UILabel()
        label.text = "No Results"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        searchbar.delegate = self
    }
    
    func setupUI() {
        view.addSubview(noResultLabel)
        view.addSubview(tableView)
        
        noResultLabel.snp.makeConstraints({ make in
            make.size.equalToSuperview()
        })
        
        tableView.snp.makeConstraints({ make in
            make.size.equalToSuperview()
        })
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView()
        
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = searchbar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        searchbar.becomeFirstResponder()
    }
    
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
//        cell.textLabel?.text = results[indexPath.row].name
        cell.configure(with: results[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // go to conversation
        let targetUserData = results[indexPath.row]
        dismiss(animated: true, completion: { [weak self] in
            guard let strongSelf = self else {return}
            if let completion = strongSelf.completion {
                completion(targetUserData)
            }
        })
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}

extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        results.removeAll()
        spinner.show(in: view)
        self.searchUser(query: text)
    }
    
    func searchUser(query: String) {
        // check if array has firebase results
        if hasFetched {
            // if it does: filter
            self.filterUser(with: query)
        }else {
            // if not, fetch then filter
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                guard let strongSelf = self else {return}
                switch result {
                case .success(let usersCollection):
                    strongSelf.users = usersCollection
                    strongSelf.hasFetched = true
                    strongSelf.filterUser(with: query)
                case .failure(let error):
                    print("fail to get users: \(error.localizedDescription)")
                }
            })
        }
    }
    
    func filterUser(with term: String) {
        guard let currentUser = UserDefaults.standard.value(forKey: "email") as? String , hasFetched else {return}
        
        let safeEmail = DatabaseManager.safeEmail(email: currentUser)
        
        let results: [SearchResult] = self.users.filter({
            guard let email = $0["email"], email != safeEmail else {
                    return false
            }
            
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            
            return name.hasPrefix(term.lowercased())
            }).compactMap({
                guard let email = $0["email"], let name = $0["name"] else {
                        return nil
                }
                
                return SearchResult(name: name, email: email)
            })
        
        self.results = results
        
        updateUI()
        
    }
    
    func updateUI() {
        spinner.dismiss()
        if results.isEmpty {
            self.noResultLabel.isHidden = false
            self.tableView.isHidden  = true
        } else {
            self.noResultLabel.isHidden = true
            self.tableView.isHidden  = false
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}
