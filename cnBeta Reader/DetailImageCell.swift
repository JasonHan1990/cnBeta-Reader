//
//  DetailImageCell.swift
//  cnBeta-Reader
//
//  Created by Juncheng Han on 2/22/17.
//  Copyright © 2017 JasonH. All rights reserved.
//

import UIKit
import Kingfisher

class DetailImageCell: BaseCell {
    
    var paragraph: Paragraph? {
        didSet {
            if let p = paragraph {
                if let imageURLString = p.paragraphString {
                    let resource = ImageResource(downloadURL: URL(string: imageURLString)!, cacheKey: imageURLString)
                    imageView.kf.setImage(with: resource, placeholder: UIImage(named: "image_placeholder"), options: [], progressBlock: nil, completionHandler: nil)
                }
            }
        }
    }
    
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "image_placeholder")
        imageView.clipsToBounds = true
        return imageView
    }()
    
    
    override func setupViews() {
        super.setupViews()
        
        addSubview(imageView)
        
        addConstraintsWithFormat("H:|-24-[v0]-24-|", views: imageView)
        addConstraintsWithFormat("V:|-24-[v0]|", views: imageView)
    }
}
