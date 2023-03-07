//
//  File.swift
//  
//
//  Created by Ralph Küpper on 3/7/23.
//

import Foundation

public struct AlchemyRequest: Codable {
    var id: Int = 1
    var jsonrpc: String = "2.0"
    var params:[String]
    var method: String
}
