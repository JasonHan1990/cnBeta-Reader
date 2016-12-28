//
//  CustomImageView.swift
//  cnBeta-Reader
//
//  Created by Juncheng Han on 12/16/16.
//  Copyright © 2016 JasonH. All rights reserved.
//

import UIKit

let imageCache: NSCache<NSString, UIImage> = {
    let imageCache = NSCache<NSString, UIImage>()
    imageCache.countLimit = 40
    return imageCache
}()

class CustomImageView: UIImageView {
    
    var imageURLString: String?
    
    func loadImageWithURLString(urlString: String?) {
        
        if let urlStr = urlString {
            imageURLString = urlStr
        
            if let imageFromCache = imageCache.object(forKey: urlStr as NSString ) {
                self.image = imageFromCache
                return
            }
        
            let url = URL(string: urlStr)
        
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, respones, error) in
            
                if error != nil {
                    print(error.debugDescription)
                    return
                }
                
                let imageToCache = UIImage(data: data!)
                
                imageCache.setObject(imageToCache!, forKey: urlStr as NSString)
            
                DispatchQueue.main.async(execute: {
                    if self.imageURLString == urlString {
                        self.image = imageToCache
                    }
                })
            
            }).resume()
        }
    }
}
