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
    
    @Field(key: "slug")
    var slug: String
    
    @Field(key: "desc")
    var desc: String
    
    @Field(key: "finalUrl")
    var finalUrl: String
    
    @Field(key: "storage")
    var storage: String
    
    @Field(key: "maxHolders")
    var maxHolders: Int
    
    @Field(key: "web3only")
    var web3only: Int
    
    // 0 = uploaded, not paid
    // 1 = uploaded and paid
    // 2 = upload, paid and stored
    
    @Field(key: "status")
    var status: Int
    
    @Field(key: "size")
    var size: Int

    @Field(key: "blockchain")
    var blockchain: String
    
    @Field(key: "contentType")
    var contentType: String
    
    @Field(key: "password")
    var password: String

    @Field(key: "downloads")
    var downloads: Int
    
    @Field(key: "fileDownloads")
    var fileDownloads: Int

    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
}
