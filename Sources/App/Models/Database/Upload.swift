//
//  File.swift
//
//
//  Created by Ralph Küpper on 12/16/22.
//

import Fluent
import Vapor

final class Upload: Model {
    static let schema = "uploads"

    init() {}

    @ID(custom: "id")
    var id: Int?
    
    @Field(key: "tokenId")
    var tokenId: String?
    
    @Field(key: "key")
    var key: String
    
    @Field(key: "transactionTx")
    var transactionTx: String
    
    @Field(key: "expectedPayment")
    var expectedPayment: Double
    
    @Field(key: "payment")
    var payment: Double
    
    @Field(key: "royaltyFee")
    var royaltyFee: Double
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "desc")
    var desc: String
    
    @Field(key: "finalUrl")
    var finalUrl: String
    
    @Field(key: "storage")
    var storage: String
    
    @Field(key: "maxHolders")
    var maxHolders: Int
    
    // 0 = uploaded, not paid
    // 1 = uploaded paid and shipped
    
    @Field(key: "status")
    var status: Int

    //
    @Field(key: "blockchain")
    var blockchain: String

    @Field(key: "downloads")
    var downloads: Int

    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
}
