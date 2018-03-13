//
//  SpritesService.swift
//  YorHa
//
//  Created by Maximilian Alexander on 3/12/18.
//  Copyright © 2018 Maximilian Alexander. All rights reserved.
//

import Foundation
import Alamofire
import SWXMLHash

struct SpriteService {
    
    func getSprites(callback: @escaping ([String]?, Error?) -> Void) {
        request("https://s3-us-west-1.amazonaws.com/edensprites/")
            .response { (response) in
                if let data = response.data {
                    let xml = SWXMLHash.parse(data)
                    let res = xml["ListBucketResult"]["Contents"].all.map({ (x) -> String in
                        return x["Key"].element?.text ?? ""
                    }).filter({ (v) -> Bool in
                        return !v.contains("blurbs")
                    }).map({ (v) -> String in
                        return "https://s3-us-west-1.amazonaws.com/edensprites/\(v)"
                    })
                    callback(res, nil)
                } else if let err = response.error {
                    callback(nil, err)
                }
            }
    }
    
    func getRandomSprite(callback: @escaping (String?, Error?) -> Void) {
        self.getSprites { (sprites, err) in
            if let sprites = sprites {
                callback(sprites.randomElement(), nil)
            } else if let err = err {
                callback(nil, err)
            }
        }
    }
    
}
