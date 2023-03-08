//
//  Access.swift
//  
//
//  Created by Ralph Küpper on 3/7/23.
//

import Fluent
import Vapor

final class Access: Model {
    static let schema = "accesses"

    init() {}

    @ID(custom: "id")
    var id: Int?
    
    @Field(key: "tokenId")
    var tokenId: String
    
    @Field(key: "transactionTx")
    var transactionTx: String
    
    @Field(key: "uploadTokenId")
    var uploadTokenId: String
    
}
