//
//  Int+RandomNumber.swift
//
//
//  Created by Ralph Küpper on 02/27/2023.
//

import Foundation

public extension Int {
    static func getRandomNum(_ min: Int, _ max: Int) -> Int {
        #if os(Linux)
        return Int(random() % max) + min
        #else
        return Int(arc4random_uniform(UInt32(max)) + UInt32(min))
        #endif
    }
}
