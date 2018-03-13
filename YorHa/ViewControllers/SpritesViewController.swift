//
//  SpritesViewController.swift
//  YorHa
//
//  Created by Maximilian Alexander on 3/13/18.
//  Copyright © 2018 Maximilian Alexander. All rights reserved.
//

import UIKit
import RealmSwift
import Cartography

class SpriteCollectionViewCell: UICollectionViewCell {
    
    static let ReuseId = "SpriteCollectionViewCell"
    
    let spriteImageView = SpriteImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(spriteImageView)
        
        constrain(spriteImageView) { (spriteImageView) -> () in
            spriteImageView.left == spriteImageView.superview!.left
            spriteImageView.right == spriteImageView.superview!.right
            spriteImageView.top == spriteImageView.superview!.top
            spriteImageView.bottom == spriteImageView.superview!.bottom
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        spriteImageView.image = nil
    }
}

class SpritesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var collectionView : UICollectionView!
    
    var spriteUrls = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Select a Sprite"
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 40, left: 20, bottom: 40, right: 20)
        layout.itemSize = CGSize(width: 80, height: 80)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonDidClick))
        
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(SpriteCollectionViewCell.self, forCellWithReuseIdentifier: SpriteCollectionViewCell.ReuseId)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        constrain(collectionView) { (collectionView) in
            collectionView.left == collectionView.superview!.left
            collectionView.top == collectionView.superview!.top
            collectionView.right == collectionView.superview!.right
            collectionView.bottom == collectionView.superview!.bottom
        }
        
        SpriteService().getSprites { [weak self] (sprites, err) in
            if let err = err {
                let alert = UIAlertController(title: "Uh oh", message: err.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (_) in
                    self?.dismiss(animated: true, completion: nil)
                }))
            } else if let sprites = sprites {
                self?.spriteUrls = sprites
                self?.collectionView.reloadData()
            }
        }
    }
    
    @objc func cancelButtonDidClick() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return spriteUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SpriteCollectionViewCell.ReuseId, for: indexPath as IndexPath) as! SpriteCollectionViewCell
        let spriteUrl = spriteUrls[indexPath.item]
        let url = URL(string: spriteUrl)!
        
        cell.spriteImageView.sd_setImage(with: url) { (image, err, cacheType, url) in
            if let downloadedImage = image {
                if cacheType == .none {
                    cell.alpha = 0
                    UIView.transition(with: cell.spriteImageView, duration: 0.25, options: [.transitionCrossDissolve], animations: {
                        cell.spriteImageView.image = downloadedImage
                        cell.alpha = 1
                    }, completion: nil)
                }
            } else {
                cell.spriteImageView.image = nil
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let spriteUrl = spriteUrls[indexPath.item]
        
        let realm = Realm.main
        if let me = realm.object(ofType: User.self, forPrimaryKey: SyncUser.current!.identity!) {
            try! realm.write {
                me.spriteUrl = spriteUrl
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
}
