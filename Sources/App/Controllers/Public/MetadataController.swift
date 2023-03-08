//
//  MetadataController.swift
//  
//
//  Created by Ralph Küpper on 3/7/23.
//

import Fluent
import Vapor
import SotoS3
import Web3
import Web3ContractABI

@available(macOS 12, *)
struct MetadataController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes
        group.get(["metadata", ":tokenId"], use: self.getMetadata)
        group.get(["access", "metadata", ":tokenId"], use: self.getAccessMetadata)
    }
    
    func getMetadata(_ req: Request) async throws -> ERC721Metadata {
        var metadata = ERC721Metadata(name: "Your file?", description: "A decentrally shared file through [blockfiles.io](https://blockfiles.io).")
        metadata.external_url = "https://blockfiles.io/"
        if let code = req.parameters.get("tokenId") {
            if let upload = try await Upload.query(on: req.db).filter(\.$tokenId == code).first() {
                if upload.status == 2 {
                    metadata.name = "Blockfiles.io: \(upload.name)"
                    metadata.external_url = "https://blockfiles.io/file/\(upload.tokenId!)/\(upload.name)"
                    metadata.attributes = []
                    metadata.attributes?.append(ERC721Metadata.Attribute(trait_type: "name", value: .string(upload.name)))
                    metadata.attributes?.append(ERC721Metadata.Attribute(trait_type: "contentType", value: .string(upload.contentType)))
                    metadata.attributes?.append(ERC721Metadata.Attribute(trait_type: "size", value: .int(upload.size)))
                    metadata.attributes?.append(ERC721Metadata.Attribute(trait_type: "downloads", value: .int(upload.downloads)))
                    metadata.attributes?.append(ERC721Metadata.Attribute(trait_type: "free", value: .bool(upload.royaltyFee == 0)))
                    metadata.attributes?.append(ERC721Metadata.Attribute(trait_type: "royaltyFee", value: .string("\(upload.royaltyFee)")))
                }
            }
        }
        return metadata
    }
    func getAccessMetadata(_ req: Request) async throws -> ERC721Metadata {
        var metadata = ERC721Metadata(name: "Access", description: "A decentrally shared access through [blockfiles.io](https://blockfiles.io).")
        metadata.external_url = "https://blockfiles.io/"
        if let code = req.parameters.get("tokenId") {
            if let access = try await Access.query(on: req.db).filter(\.$tokenId == code).first() {
                let upload = try await Upload.query(on: req.db).filter(\.$tokenId == access.uploadTokenId).first()!
                metadata.name = "Blockfiles.io Access"
                metadata.external_url = "https://blockfiles.io/file/\(access.uploadTokenId)/\(upload.name)"
                metadata.attributes = []
                    
            }
        }
        return metadata
    }
    
    
    func validate(_ req: Request) async throws -> HTTPStatus{
        if let code = req.parameters.get("code") {
            if let upload = try await Upload.query(on: req.db).filter(\.$key == code).first() {
                if upload.status == 0 {
                    try await validateUpload(upload: upload, on: req)
                }
                return .ok
            }
        }
        throw Abort(.badRequest, reason: "Cannot load it.")
    }
    func finalize(_ req: Request) async throws -> HTTPStatus{
        if let code = req.parameters.get("code") {
            if let upload = try await Upload.query(on: req.db).filter(\.$key == code).first() {
                if upload.status == 1 {
                    try await finalizeUpload(upload: upload, on: req)
                }
                return .ok
            }
        }
        throw Abort(.badRequest, reason: "Cannot load it.")
    }
    
    func finalizeUpload(upload: Upload, on req: Request) async throws -> Bool {
        if upload.finalUrl != "" || upload.status == 2 {
            Abort(.badRequest, reason: "Already finalized this transaction")
        }
        if upload.storage == "s3" {
            let s3 = S3(client: req.application.awsClient)
            let url = "https://s3.amazonaws.com/upload.blockfiles.io/\(upload.key)"
            try await s3.copyObject(S3.CopyObjectRequest(bucket: "final.blockfiles.io", copySource: "\(url)", key: upload.key))
            try await s3.deleteObject(S3.DeleteObjectRequest(bucket: "upload.blockfiles.io", key: upload.key))
            
            upload.finalUrl = "https://s3.amazonaws.com/final.blockfiles.io/\(upload.key)"
            upload.status = 2
            try await upload.save(on: req.db)
            return true
        }
        return false
    }
    
    func validateUpload(upload: Upload, on req: Request) async throws -> Bool {
        // step 0: make sure we have not ever used this transaction before
        let uploads = try await Upload.query(on: req.db).filter(\.$status > 0).filter(\.$transactionTx == upload.transactionTx).count()
        if uploads > 0 {
            Abort(.badRequest, reason: "Already used this transaction")
        }
        
        
        // step 1: get the transaction
        // we get the transaction and validate that the owner, sender and receiver are correct
        struct AlchemyTransactionResponse: Codable {
            struct Result: Codable {
                var blockHash: String
                var blockNumber: String
                var hash: String
                var chainId: String
                var from: String
                var input: String
                var value: String
            }
            var result: Result
        }
        let url = String.getAlchemyApiUrl(upload.blockchain)
        let input = AlchemyRequest(params: [upload.transactionTx], method: "eth_getTransactionByHash")
        let inputString = String(data: try JSONEncoder().encode(input), encoding: .utf8)!
        let res1 = try await req.client.post("\(url)", beforeSend: { r in
            r.body = ByteBufferAllocator().buffer(capacity: inputString.count)
            r.body?.writeString(inputString)
        })
        let res = try res1.content.decode(AlchemyTransactionResponse.self)
        let web3 = Web3(rpcURL: url)
        let parsed = try web3.eth.abi.decodeParameters([
            SolidityFunctionParameter(name: "sizeInMB", type: .uint256),
            SolidityFunctionParameter(name: "owner", type: .address),
            SolidityFunctionParameter(name: "maxHolders", type: .uint256),
            SolidityFunctionParameter(name: "royaltyFee", type: .uint256),
            
        ], from: String(res.result.input.suffix(res.result.input.count-10)))
        let adr = parsed["owner"] as! EthereumAddress
        let ownerAddress = adr.hex(eip55: true)
        print("owner: ", ownerAddress)
        // step 2: get transfers for this transaction
        struct AlchemyTransferResponse: Codable {
            struct Result: Codable {
                struct Transfer: Codable {
                    var blockNum: String
                    var hash: String
                    var from: String
                    var to: String
                    var value: Double?
                    var erc721TokenId: String?
                    var tokenId: String?
                }
                var transfers: [Transfer]
            }
            var result: Result
        }
        let transferRequestInput = TransferAlchemyRequest(params: [
            TransferAlchemyRequest.Params(
                fromBlock: res.result.blockNumber,
                toBlock: res.result.blockNumber,
                toAddress: ownerAddress,
                contractAddresses: [
                    String.getBlockfilesSmartContractAddress(upload.blockchain)
                ],
                category: ["erc721"])
        ],
                                                          method: "alchemy_getAssetTransfers")
        let inputString2 = String(data: try JSONEncoder().encode(transferRequestInput), encoding: .utf8)!
        let res2 = try await req.client.post("\(url)", beforeSend: { r in
            r.body = ByteBufferAllocator().buffer(capacity: inputString2.count)
            r.body?.writeString(inputString2)
        })
        let transfers = try res2.content.decode(AlchemyTransferResponse.self).result.transfers
        if transfers.count == 0 {
            throw Abort(.badRequest, reason: "No transfers to the owner, invalid transaction tx.")
        }
        var validTransaction = false
        var tokenId = 0
        for transfer in transfers {
            if transfer.from.lowercased() == "0x0000000000000000000000000000000000000000" &&
                transfer.to.lowercased() == ownerAddress.lowercased() &&
                transfer.hash.lowercased() == upload.transactionTx.lowercased() &&
                transfer.blockNum.lowercased() == res.result.blockNumber.lowercased() &&
                transfer.tokenId != nil {
                validTransaction = true
                tokenId = transfer.tokenId!.hexaToDecimal
            }
        }
        if validTransaction {
            upload.tokenId = "\(tokenId)"
            upload.status = 1
            try await upload.save(on: req.db)
            return true
        }
        else {
            print("f: ", transfers)
        }
        return false
    }

}
