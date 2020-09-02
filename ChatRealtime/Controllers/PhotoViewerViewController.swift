//
//  PhotoViewerViewController.swift
//  ChatRealtime
//
//  Created by Apple on 7/29/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

class PhotoViewerViewController: UIViewController {

    private var url: URL
    
    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        self.title = "Photo"
        self.navigationItem.largeTitleDisplayMode = .never
        // Do any additional setup after loading the view.
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.snp.makeConstraints({ make in
            make.size.equalTo(view)
        })
    }
    private func setupUI() {
        view.addSubview(imageView)
        imageView.sd_setImage(with: self.url, completed: nil)
    }
    
}
