//
//  SpriteImageView.swift
//  YorHa
//
//  Created by Maximilian Alexander on 3/13/18.
//  Copyright © 2018 Maximilian Alexander. All rights reserved.
//

import UIKit

class SpriteImageView: UIImageView {
    
    init() {
        super.init(frame: .zero)
        layer.magnificationFilter = kCAFilterNearest
        contentMode = .scaleAspectFit
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
