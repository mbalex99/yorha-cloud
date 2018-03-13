//
//  User.swift
//  YorHa
//
//  Created by Maximilian Alexander on 3/12/18.
//  Copyright © 2018 Maximilian Alexander. All rights reserved.
//

import Foundation
import RealmSwift

class User: Object {
    
    @objc dynamic var userId: String = ""
    @objc dynamic var spriteUrl: String = ""
    @objc dynamic var nickname: String = ""
    
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0
    @objc dynamic var lastSeenTimestamp: Date = Date()
    
    let thoughts = List<Thought>()

    override static func primaryKey() -> String? {
        return "userId"
    }
}

class Thought: Object {
    
    @objc dynamic var thoughtId: String = UUID().uuidString
    @objc dynamic var timestamp: Date = Date()
    @objc dynamic var body: String = ""
    
    override static func primaryKey() -> String? {
        return "thoughtId"
    }
}
