//
//  ProfileViewController.swift
//  ChatRealtime
//
//  Created by Apple on 7/29/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import SnapKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import FirebaseStorage

class ProfileViewController: UIViewController {

    private let tableView: UITableView = {
        let tableview = UITableView()
        
        return tableview
    }()
    
    let data = ["Log Out"]
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupUI()
    }
    
    func setupUI() {
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints{ make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.tableHeaderView = createTableViewHeader()
    }
    
    func createTableViewHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/\(fileName)"
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
//        headerView.backgroundColor = .link
        
        let imageView: UIImageView = {
            let imgview = UIImageView()
            
            return imgview
        }()
        
        headerView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 150 / 2
        imageView.snp.makeConstraints({make in
            make.width.height.equalTo(150)
            make.center.equalTo(headerView)
        })
        
        StorageManager.shared.downloadURL(for: path, completion: {[weak self] result in
            guard let strongSelf = self else {return}
            
            switch(result) {
            case .failure(let error):
                print("error: \(error.localizedDescription)")
            case .success(let url):
                strongSelf.downloadURL(imageView: imageView, url: url)
            }
        })
        return headerView
    }
    
    func downloadURL(imageView: UIImageView, url: URL) {
        let dataTask = URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
            guard let data = data, error == nil else { return}
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }
        })
        dataTask.resume()
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .left
        cell.textLabel?.textColor = .black
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let alert = UIAlertController(title: "Oop!", message: "Please choose", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: {[weak self]_ in
            guard let strongSelf = self else {return}
            
            // Log out facebook
            LoginManager().logOut()
            
            // Log out google
            GIDSignIn.sharedInstance()?.signOut()
            
            do {
                try Auth.auth().signOut()
                let vc = LoginViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                strongSelf.present(nav, animated: true, completion: nil)
            }catch {
                
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
        
    }
}
