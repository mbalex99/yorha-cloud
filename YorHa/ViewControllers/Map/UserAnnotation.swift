//
//  SpritesAnnotation.swift
//  YorHa
//
//  Created by Maximilian Alexander on 3/12/18.
//  Copyright © 2018 Maximilian Alexander. All rights reserved.
//

import MapKit
import SDWebImage
import RealmSwift
import THLabel
import Cartography

@objc class UserAnnotation: NSObject, MKAnnotation {
    
    @objc dynamic var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    
    var token: NotificationToken?
    let user: User
    
    init(user: User) {
        self.user = user
        self.coordinate = CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude)
        super.init()
        token = self.user.observe { [weak self] (change) in
            guard let `self` = self else { return }
            self.animateCoordinate(coordinate: CLLocationCoordinate2D(latitude: self.user.latitude, longitude: self.user.longitude))
        }
    }
    
    func animateCoordinate(coordinate: CLLocationCoordinate2D){
        UIView.animate(withDuration: 0.25, animations: {
            self.coordinate = coordinate
        }) { (_) in
            self.coordinate = coordinate
        }
    }

    deinit {
        token?.invalidate()
    }
}


class MapMessageLabel : UILabel {
    
    init(){
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsetsMake(3, 8, 3, 8)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
    
}


class UserAnnotationView: MKAnnotationView {
    
    static let ReuseId = "UserAnnotationView"
    
    lazy var spriteImageView: UIImageView = {
        let i = UIImageView()
        i.contentMode = .scaleAspectFit
        i.layer.magnificationFilter =  kCAFilterNearest
        return i
    }()
    
    lazy var nameLabel: THLabel = {
        let t = THLabel()
        t.strokeColor = .white
        t.strokeSize = 2
        t.textAlignment = .center
        t.font = UIFont.boldSystemFont(ofSize: 14)
        return t
    }()
    
    lazy var messageLabel: MapMessageLabel = {
        let s = MapMessageLabel()
        s.textColor = .white
        s.text = ""
        s.font = UIFont.systemFont(ofSize: 14)
        s.backgroundColor = .black
        s.layer.cornerRadius = 8.0
        s.layer.masksToBounds = true
        return s
    }()
    
    lazy var speechLabelTail: UIImageView = {
        let s = UIImageView(image: UIImage(named: "speech_label_tail")?.withRenderingMode(.alwaysTemplate))
        s.contentMode = .scaleAspectFit
        s.tintColor = .black
        return s
    }()
    
    var token: NotificationToken?
    
    init(annotation: UserAnnotation){
        super.init(annotation: annotation, reuseIdentifier: UserAnnotationView.ReuseId)
        self.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        addSubview(spriteImageView)
        addSubview(nameLabel)
        addSubview(messageLabel)
        addSubview(speechLabelTail)
        
        constrain([spriteImageView, nameLabel, messageLabel, speechLabelTail]) { (proxies) in
            let spriteImageView = proxies[0]
            let nameLabel = proxies[1]
            let messageLabel = proxies[2]
            let speechLabelTail = proxies[3]
            
            spriteImageView.height == 48
            spriteImageView.width == 48
            spriteImageView.centerX == spriteImageView.superview!.centerX
            spriteImageView.centerY == spriteImageView.superview!.centerY
            
            messageLabel.height >= 30
            messageLabel.height <= 100
            messageLabel.width <= 200
            messageLabel.width >= 100
            messageLabel.centerX == spriteImageView.centerX
            messageLabel.bottom == spriteImageView.top - 10
            
            speechLabelTail.centerX == spriteImageView.centerX + 20
            speechLabelTail.height == 20
            speechLabelTail.width == 20
            speechLabelTail.bottom == spriteImageView.top + 8
            
            
            nameLabel.left == nameLabel.superview!.left
            nameLabel.right == nameLabel.superview!.right
            nameLabel.top == spriteImageView.bottom
            nameLabel.bottom == nameLabel.superview!.bottom
            
        }
        
        setupWithUser(user: annotation.user)
    }
    
    override var annotation: MKAnnotation? {
        didSet(val){
            guard let userAnnotation = val as? UserAnnotation else { return }
            setupWithUser(user: userAnnotation.user)
        }
    }
    
    func setupWithUser(user: User) {
        token?.invalidate()
        self.spriteImageView.sd_setImage(with: URL(string: user.spriteUrl), completed: nil)
        self.nameLabel.text = user.nickname
        self.nameLabel.textColor = user.userId == SyncUser.current!.identity! ? Constants.Colors.primaryColor : .black
        
        if let lastThought = user.thoughts.last {
            self.messageLabel.isHidden = false
            self.speechLabelTail.isHidden = false
            self.messageLabel.text = lastThought.body
        } else {
            self.messageLabel.isHidden = true
            self.speechLabelTail.isHidden = true
        }
        
        guard let myUserId = SyncUser.current?.identity else { return }
        self.messageLabel.backgroundColor = myUserId == user.userId ? Constants.Colors.primaryColor : .black
        self.speechLabelTail.tintColor = myUserId == user.userId ? Constants.Colors.primaryColor : .black
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        token?.invalidate()
    }
    
}
