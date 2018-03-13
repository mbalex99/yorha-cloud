//
//  Array+Extensions.swift
//  YorHa
//
//  Created by Maximilian Alexander on 3/12/18.
//  Copyright © 2018 Maximilian Alexander. All rights reserved.
//

import Foundation

extension Collection where Index == Int {
    
    /**
     Picks a random element of the collection.
     
     - returns: A random element of the collection.
     */
    func randomElement() -> Iterator.Element? {
        return isEmpty ? nil : self[Int(arc4random_uniform(UInt32(endIndex)))]
    }
    
}
