//
//  Realm+Extensions.swift
//  YorHa
//
//  Created by Maximilian Alexander on 3/12/18.
//  Copyright © 2018 Maximilian Alexander. All rights reserved.
//

import Foundation
import RealmSwift

extension Realm {
    
    static var main: Realm {
        let url = URL(string: Constants.REALM_URL)!.appendingPathComponent("main")
        let config = SyncConfiguration(user: SyncUser.current!, realmURL: url)
        return try! Realm(configuration: Realm.Configuration(syncConfiguration: config))
    }
    
    static func mainAsync(callback: @escaping (Realm?, Swift.Error?) -> Void) {
        let url = URL(string: Constants.REALM_URL)!.appendingPathComponent("main")
        let config = SyncConfiguration(user: SyncUser.current!, realmURL: url)
        Realm.asyncOpen(configuration: Realm.Configuration(syncConfiguration: config), callbackQueue: .main, callback: callback)
    }
}
