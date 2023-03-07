//
//  TransferAlchemyRequest.swift
//  
//
//  Created by Ralph Küpper on 3/7/23.
//

import Foundation

public struct TransferAlchemyRequest: Codable {
    struct Params: Codable {
        var fromBlock: String
        var toBlock: String
        var toAddress: String
        var contractAddresses:[String]
        var category: [String]
    }
    var id: Int = 1
    var jsonrpc: String = "2.0"
    
    var params:[Params]
    var method: String
}
