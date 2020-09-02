//
//  NewConversationCell.swift
//  ChatRealtime
//
//  Created by Apple on 8/29/20.
//  Copyright © 2020 Apple. All rights reserved.
//


import UIKit
import SnapKit
import SDWebImage

class NewConversationCell: UITableViewCell {
    
    static let identifier = "NewConversationCell"
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 35
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // do your thing
        userImageView.snp.makeConstraints({ make in
            make.width.height.equalTo(70)
            make.top.equalTo(contentView.snp.top).offset(10)
            make.left.equalTo(contentView.snp.left).offset(10)
        })
        
        userNameLabel.snp.makeConstraints({ make in
            make.top.bottom.equalTo(contentView).offset(0)
            make.left.equalTo(userImageView.snp.right).offset(10)
            make.right.equalTo(contentView.snp.right).offset(-20)
//            make.height.equalTo(contentView.height - 20)
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func configure(with model: SearchResult) {
        self.userNameLabel.text = model.name
        
        let path = "images/\(model.email)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let url):
                
                DispatchQueue.main.async {
                    strongSelf.userImageView.sd_setImage(with: url, completed: nil)
                }
                
            case .failure(let error):
                print("fail to get image url: \(error.localizedDescription)")
            }
        })
    }
}
