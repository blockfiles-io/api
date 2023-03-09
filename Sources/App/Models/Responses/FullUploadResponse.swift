//
//  FullUploadResponse.swift
//  
//
//  Created by Ralph Küpper on 3/7/23.
//

import Vapor

public struct FullUploadResponse: Content {
    var url: String
    var key: String
    var id: Int?
    var tokenId: String?
    var transactionTx: String
    var expectedPayment: Double
    var payment: Double
    var royaltyFee: Double
    var name: String
    var desc: String
    var finalUrl: String
    var storage: String
    var maxHolders: Int
    var status: Int
    var size: Int
    var blockchain: String
    var contentType: String
    var downloads: Int
    var hasPassword: Bool
    var web3only: Bool
    var createdAt: Date?
    
    init (_ up: Upload) {
        self.url = up.finalUrl
        self.key = up.key
        self.tokenId = up.tokenId
        self.transactionTx = up.transactionTx
        self.expectedPayment = up.expectedPayment
        self.payment = up.payment
        self.royaltyFee = up.royaltyFee
        self.name = up.name
        self.desc = up.desc
        self.web3only = up.web3only == 1
        self.hasPassword = up.password != ""
        self.finalUrl = up.finalUrl
        self.storage = up.storage
        self.maxHolders = up.maxHolders
        self.status = up.status
        self.size = up.size
        self.contentType = up.contentType
        self.blockchain = up.blockchain
        self.downloads = up.downloads
        self.createdAt = up.createdAt
    }
}
