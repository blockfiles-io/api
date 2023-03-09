//
//  UploadController.swift
//
//
//  Created by Ralph Küpper on 02/27/2023.
//

import Fluent
import Vapor
import SotoSignerV4
import SotoS3
import Web3
import Web3ContractABI

struct BlockchainValidationResponse: Content {
    var blockchainConfirmed: Bool = false
    var url: String? = nil
}

@available(macOS 12, *)
struct UploadController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes
        group.post("process", use: self.processUpload)
        group.get(":code", use: self.getUpload)
        group.get(["validate", ":code"], use: self.validate)
        group.get(["finalize", ":code"], use: self.finalize)
    }

    
    /*
     This function only processes the upload in so far as it tells the system to "expect" it to be ready. Once the blockchain transaction is through
     we get notified and can process the upload.
     */
    func processUpload(_ req: Request) async throws -> FullUploadResponse {
        struct RequestData: Codable {
            var transactionTx: String
            var network: String
            var expectedPayment: Double
            var royaltyFee: Double
            var maxHolders: Int
            var name: String
            var password: String
            var size: Int
            var web3only: Bool
            var storage: String // only s3 for now
        }
        let requestData = try req.content.decode(RequestData.self)
        let s3 = S3(client: req.application.awsClient)
        let upload = Upload()
        upload.size = requestData.size
        upload.contentType = ""
        
        upload.blockchain = requestData.network
        upload.key = String.randomString(length: 10)
        upload.transactionTx = requestData.transactionTx
        upload.expectedPayment = requestData.expectedPayment
        upload.royaltyFee = requestData.royaltyFee
        upload.maxHolders = requestData.maxHolders
        upload.name = requestData.name
        upload.web3only = requestData.web3only ? 1 : 0
        upload.password = ""
        if requestData.password != "" {
            upload.password = try Bcrypt.hash(requestData.password)
        }
        upload.slug = requestData.name.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789").inverted).replacingOccurrences(of: ".", with: "-")
        upload.desc = ""
        upload.downloads = 0
        upload.fileDownloads = 0
        upload.status = 0
        upload.tokenId = nil
        upload.payment = 0
        upload.finalUrl = ""
        upload.storage = requestData.storage
        try await upload.save(on: req.db)
        return FullUploadResponse(upload)
    }
    
    func getUpload(_ req: Request) async throws -> FullUploadResponse {
        if let code = req.parameters.get("code") {
            if let upload = try await Upload.query(on: req.db).filter(\.$key == code).first() {
                print("upload: ", upload)
                return FullUploadResponse(upload)
            }
        }
        throw Abort(.badRequest, reason: "Cannot load it.")
    }
    
    
    func validate(_ req: Request) async throws -> BlockchainValidationResponse {
        if let code = req.parameters.get("code") {
            if let upload = try await Upload.query(on: req.db).filter(\.$key == code).first() {
                var val = false
                var url:String? = nil
                if upload.status == 0 {
                    val = try await validateUpload(upload: upload, on: req)
                    let cred = try await req.application.awsClient.credentialProvider.getCredential(on: req.eventLoop, logger: req.logger).get()
                    let signer = AWSSigner(credentials: cred, name: "s3", region: "us-east-1")
                    let signedURL = signer.signURL(url: URL(string: "https://s3.amazonaws.com/upload.blockfiles.io/\(upload.key)")!, method: .PUT, expires: .minutes(60))
                    
                    url = signedURL.absoluteString
                }
                return BlockchainValidationResponse(blockchainConfirmed: val, url: url)
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
            
            let file = try await s3.headObject(S3.HeadObjectRequest(bucket: "upload.blockfiles.io", key: upload.key))
            if let s = file.contentLength {
                upload.size = Int(s)
            }
            if let s = file.contentType {
                upload.contentType = s
            }
            
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
        let uploads = try await Upload.query(on: req.db).filter(\.$status > 0).filter(\.$transactionTx == upload.transactionTx).filter(\.$blockchain == upload.blockchain).count()
        if uploads > 0 {
            Abort(.badRequest, reason: "Already used this transaction")
        }
        
        
        // step 1: get the transaction
        // we get the transaction and validate that the owner, sender and receiver are correct
        struct AlchemyTransactionResponse: Codable {
            struct Result: Codable {
                var blockHash: String?
                var blockNumber: String?
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
        if res.result.blockNumber == nil {
            return false
        }
        let transferRequestInput = TransferAlchemyRequest(params: [
            TransferAlchemyRequest.Params(
                fromBlock: res.result.blockNumber!,
                toBlock: res.result.blockNumber!,
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
                transfer.blockNum.lowercased() == res.result.blockNumber!.lowercased() &&
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
