//
//  DetailController.swift
//  cnBeta Reader
//
//  Created by Juncheng Han on 12/14/16.
//  Copyright © 2016 JasonH. All rights reserved.
//

import UIKit
import Alamofire
import Toast_Swift
import Kanna
import CoreData

typealias contentParsingCompletion = ([Paragraph]?) -> Void

class DetailController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var selectedFeed: Feed?
    fileprivate var URLString: String?
    var timeLabelText: String?
    
    var contentArray: [Paragraph]?
    var allImageParagraphs: [Paragraph]?
    
    let titleCellId = "titleCellId"
    let textCellId = "textCellId"
    let summCellId = "summCellId"
    
    let zoomImageController: ZoomImageController = {
        let controller = ZoomImageController()
        return controller
    }()
    
    let imageDisplayController: ImageDisplayController = {
        let controller = ImageDisplayController()
        return controller
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        collectionView?.register(TextCell.self, forCellWithReuseIdentifier: textCellId)
        collectionView?.register(TitleCell.self, forCellWithReuseIdentifier: titleCellId)
        collectionView?.register(SummCell.self, forCellWithReuseIdentifier: summCellId)
        collectionView?.backgroundColor = .white

        view.backgroundColor = .white
        
        setupNavigationBar()
        
        contentArray = [Paragraph]()
        allImageParagraphs = [Paragraph]()
        
        if let date = selectedFeed?.publishedDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE MMM-dd-yyyy HH:mm"
            timeLabelText = dateFormatter.string(from: date as Date)
        }

        // Create title
        if let title = selectedFeed?.title {
            // print(title)
            let titleParagraph = Paragraph.init(type: .title, content: title, alignment: .alignmentLeft, textStyle: .strong)
            contentArray?.append(titleParagraph)
        }
        
        print(selectedFeed?.link ?? "")
        
        if let last10  = selectedFeed?.link?.substring(from:(selectedFeed?.link?.index((selectedFeed?.link?.endIndex)!, offsetBy: -10))!) {
        
            let urlString = "http://m.cnbeta.com/view/\(last10)"
        
            print(urlString)
            URLString = urlString
            
            if let data = selectedFeed?.savedContent as? Data {
                
                if let content = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Paragraph] {
                    contentArray? += content
                    collectionView?.reloadData()
                    
                    self.getAllImageParagraphs(self.contentArray)
                }
            } else {
                view.makeToastActivity(.center)
                DispatchQueue.global(qos: .default).async {
                    self.getWebContentWithUrl(urlString, completion: { contents in
                        DispatchQueue.main.async {
                            self.view.hideToastActivity()
                        
                            if let newFeeds = contents {
                                self.contentArray? += newFeeds
                                self.collectionView?.reloadData()
                                
                                self.getAllImageParagraphs(self.contentArray)
                            }
                        }
                    })
                }
            }
        }
    }
    
    func getAllImageParagraphs(_ allContents: [Paragraph]?) {
        if let allContents = allContents {
            for paragraph in allContents {
                if paragraph.type == .image {
                    allImageParagraphs?.append(paragraph)
                }
            }
        }
    }
    
    func setupNavigationBar() {
        
        let myLogoView = UIImageView(image: UIImage(named: "logo"))
        navigationItem.titleView = myLogoView
        
        let backButton = UIBarButtonItem(image: UIImage(named: "nav_back")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleNavBack))
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpace.width = -8
        
        let saveImage = (selectedFeed?.isSaved)! ? "Saved" : "Save"
        let saveButton = UIBarButtonItem(image: UIImage(named: saveImage), style: .plain, target: self, action: #selector(handleSave))
        saveButton.tintColor = Constants.All_ICONS_COLOR
        
        let moreButton = UIBarButtonItem(image: UIImage(named: "nav_more"), style: .plain, target: self, action: #selector(handleNavMore))
        moreButton.tintColor = Constants.All_ICONS_COLOR
        
        navigationItem.leftBarButtonItems = [fixedSpace, backButton]
        navigationItem.rightBarButtonItems = [moreButton, saveButton]
    }
    
    func handleSave(_ sender: UIBarButtonItem) {
        
        if selectedFeed?.isSaved == false {
            view.makeToast("Feed saved", duration: 0.5, position: CGPoint(x: (self.collectionView?.frame.width)! / 2.0,y: (self.collectionView?.frame.height)! - 80))
            sender.image = UIImage(named: "Saved")?.withRenderingMode(.alwaysOriginal)
        } else {
            view.makeToast("Feed unsaved", duration: 0.5, position: CGPoint(x: (self.collectionView?.frame.width)! / 2.0,y: (self.collectionView?.frame.height)! - 80))
            sender.image = UIImage(named: "Save")?.withRenderingMode(.alwaysOriginal)
        }
        
        selectedFeed?.isSaved = !(selectedFeed?.isSaved)!
        CoreDataStack.sharedInstance.save()
    }
    
    func handleNavBack(_ sender: UIBarButtonItem) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func handleNavMore(_ sender: UIBarButtonItem) {
        view.makeToast("Nothing in here yet", duration: 1.2, position: CGPoint(x: (self.collectionView?.frame.width)! / 2.0,y: (self.collectionView?.frame.height)! - 80))
        
        // TODO: open in browser and share
        //UIApplication.shared.openURL(URL(string: (selectedFeed?.link)!)!)
    }
    
    
    // MARK: Collection View Delegate and Data source
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contentArray?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let currentParagragh = contentArray?[indexPath.item]
        if currentParagragh?.type == .title {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: titleCellId, for: indexPath) as! TitleCell
            
            cell.paragraph = contentArray?[indexPath.item]
            cell.timeLabel.text = timeLabelText
            
            return cell
        } else if currentParagragh?.type == .summary {
        
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: summCellId, for: indexPath) as! SummCell
        
            cell.paragraph = contentArray?[indexPath.item]
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: textCellId, for: indexPath) as! TextCell
            
            cell.paragraph = contentArray?[indexPath.item]
            return cell
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentParagragh = contentArray?[indexPath.item]
        if currentParagragh?.type == .image {
            // get all images paragraph
            var imageIndex: Int = 0
            for imageParagraph in allImageParagraphs! {
                if imageParagraph == currentParagragh {
                    break
                }
                imageIndex += 1
            }
            
            imageDisplayController.imagesInfo = (allImageParagraphs!, imageIndex)
            imageDisplayController.show()
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paragraph = contentArray?[indexPath.item]
        
        if paragraph?.type == .title {
            let height = contentArray?[indexPath.item].paragraphHeight
            
            return CGSize(width: collectionView.frame.width, height: 30 + CGFloat(height!) + 6 + 16)
        } else {
        
            let height = contentArray?[indexPath.item].paragraphHeight
        
            return CGSize(width: collectionView.frame.width, height: CGFloat(height!) + 36)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func getWebContentWithUrl(_ urlString: String, completion: @escaping contentParsingCompletion) {
        
        
        let url = URL(string: urlString);
        let cnbetaData = try? Data(contentsOf: url!)
            
        if let cnbetaData = cnbetaData {
                
            var contents = [Paragraph]()
                
                
            if let doc = HTML(html: cnbetaData, encoding: .utf8) {
                    
                // article sum
                for link in doc.css("div.article-summ") {
                        
                    if link.text != "" {
                        let paragraph = Paragraph.init(type: .summary, content: link.text!, alignment: .alignmentLeft,  textStyle: .normal)
                        contents.append(paragraph)

                    }
                }
                    
                // article content
                for link in doc.css("div.articleCont p") {
                        
                    let text = link.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                    if text == "" {
                        // image or video
                        // print("image")
                        for imageNode in link.css("img") {
                            if let imageSrc = imageNode["src"] {
                                //print(imageSrc)
                                let paragraph = Paragraph.init(type: .image, content: imageSrc, alignment: .alignmentCenter)
                                contents.append(paragraph)
                            }
                        }
                            
                    } else {
                        var textStyle: TextStyle = .normal
                        if link.css("strong").first?.text != nil {
                            textStyle = .strong
                        }
                            
                        var textAlignment: ParagraphAlignment = .alignmentLeft
                        if link["style"] == "text-align: center;" {
                            textAlignment = .alignmentCenter
                        } else if link["style"] == "text-align: right;"{
                            textAlignment = .alignmentRight
                        }
                            
                        let paragraph = Paragraph.init(type: .text, content: text!, alignment: textAlignment,  textStyle: textStyle)
                            
                        contents.append(paragraph)
                            
                    }
                }
            }
                
            let data = NSKeyedArchiver.archivedData(withRootObject: contents)
            self.selectedFeed?.savedContent = data as NSData
                
            if self.URLString == urlString {
                completion(contents)
            }
        } else {
            print("The url is inaccessible")
            if self.URLString == urlString {
                completion(nil)
            }
        }
    }
}
