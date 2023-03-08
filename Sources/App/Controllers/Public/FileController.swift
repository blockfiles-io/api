//
//  FileController.swift
//  
//
//  Created by Ralph Küpper on 3/7/23.
//

import Fluent
import Vapor
import SotoS3
import Web3
import Web3ContractABI
import CryptoSwift
import secp256k1
import SotoSignerV4
import SotoS3

// Not the prettiest, but necessary since we are waiting for this PR:
// https://github.com/Boilertalk/Web3.swift/pull/124
// Once merged we will remove this ugly custom class.
public final class EthereumPublicKeyCustom {

    // MARK: - Properties

    /// The raw public key bytes
    public let rawPublicKey: Bytes

    /// The `EthereumAddress` associated with this public key
    public let address: EthereumAddress

    /// True iff ctx should not be freed on deinit
    private let ctxSelfManaged: Bool

    /// Internal context for secp256k1 library calls
    private let ctx: OpaquePointer

    // MARK: - Initialization

    /**
     * Initializes a new instance of `EthereumPublicKey` with the message and corresponding signature.
     * This is done by extracting the public key from the recoverable signature, which guarantees a
     * valid signature.
     *
     * - parameter message: The original message which will be used to generate the hash which must match the given signature.
     * - paramater v: The recovery id of the signature. Must be 0, 1, 2 or 3 or Error.signatureMalformed will be thrown.
     * - parameter r: The r value of the signature.
     * - parameter s: The s value of the signature.
     *
     * - parameter ctx: An optional self managed context. If you have specific requirements and
     *                  your app performs not as fast as you want it to, you can manage the
     *                  `secp256k1_context` yourself with the public methods
     *                  `secp256k1_default_ctx_create` and `secp256k1_default_ctx_destroy`.
     *                  If you do this, we will not be able to free memory automatically and you
     *                  __have__ to destroy the context yourself once your app is closed or
     *                  you are sure it will not be used any longer. Only use this optional
     *                  context management if you know exactly what you are doing and you really
     *                  need it.
     *
     * - throws: EthereumPublicKey.Error.signatureMalformed if the signature is not valid or in other ways malformed.
     *           EthereumPublicKey.Error.internalError if a secp256k1 library call or another internal call fails.
     */
    public init(message: Bytes, v: EthereumQuantity, r: EthereumQuantity, s: EthereumQuantity, ctx: OpaquePointer? = nil) throws {
        // Create context
        let finalCtx: OpaquePointer
        if let ctx = ctx {
            finalCtx = ctx
            self.ctxSelfManaged = true
        } else {
            let ctx = try secp256k1_default_ctx_create(errorThrowable: Error.internalError)
            finalCtx = ctx
            self.ctxSelfManaged = false
        }
        self.ctx = finalCtx
        // Create raw signature array
        var rawSig = Bytes()
        var r = r.quantity.makeBytes().trimLeadingZeros()
        var s = s.quantity.makeBytes().trimLeadingZeros()

        guard r.count <= 32 && s.count <= 32 else {
            throw Error.signatureMalformed
        }
        guard let vUInt = v.quantity.makeBytes().bigEndianUInt, vUInt <= Int32.max else {
            throw Error.signatureMalformed
        }
        let v = Int32(vUInt)

        for _ in 0..<(32 - r.count) {
            r.insert(0, at: 0)
        }
        for _ in 0..<(32 - s.count) {
            s.insert(0, at: 0)
        }

        rawSig.append(contentsOf: r)
        rawSig.append(contentsOf: s)
        
        // Parse recoverable signature
        guard let recsig = malloc(MemoryLayout<secp256k1_ecdsa_recoverable_signature>.size)?.assumingMemoryBound(to: secp256k1_ecdsa_recoverable_signature.self) else {
            throw Error.internalError
        }
        defer {
            free(recsig)
        }
        
        guard secp256k1_ecdsa_recoverable_signature_parse_compact(finalCtx, recsig, &rawSig, v) == 1 else {
            throw Error.signatureMalformed
        }

        // Recover public key
        guard let pubkey = malloc(MemoryLayout<secp256k1_pubkey>.size)?.assumingMemoryBound(to: secp256k1_pubkey.self) else {
            throw Error.internalError
        }
        defer {
            free(pubkey)
        }
        var hash = SHA3(variant: .keccak256).calculate(for: message)
        guard hash.count == 32 else {
            throw Error.internalError
        }
        guard secp256k1_ecdsa_recover(finalCtx, pubkey, recsig, &hash) == 1 else {
            throw Error.signatureMalformed
        }

        // Generate uncompressed public key bytes
        var rawPubKey = Bytes(repeating: 0, count: 65)
        var outputlen = 65
        guard secp256k1_ec_pubkey_serialize(finalCtx, &rawPubKey, &outputlen, pubkey, UInt32(SECP256K1_EC_UNCOMPRESSED)) == 1 else {
            throw Error.internalError
        }

        rawPubKey.remove(at: 0)
        self.rawPublicKey = rawPubKey

        // Generate associated ethereum address
        var pubHash = SHA3(variant: .keccak256).calculate(for: rawPubKey)
        guard pubHash.count == 32 else {
            throw Error.internalError
        }
        pubHash = Array(pubHash[12...])
        self.address = try EthereumAddress(rawAddress: pubHash)
    }

    

    /**
     * Returns this public key serialized as a hex string.
     */
    public func hex() -> String {
        var h = "0x"
        for b in rawPublicKey {
            h += String(format: "%02x", b)
        }

        return h
    }


    // MARK: - Errors

    public enum Error: Swift.Error {

        case internalError
        case keyMalformed
        case signatureMalformed
    }

    // MARK: - Deinitialization

    deinit {
        if !ctxSelfManaged {
            secp256k1_context_destroy(ctx)
        }
    }
}
extension Array where Element == Byte {

    func trimLeadingZeros() -> Bytes {
        let oldBytes = self
        var bytes = Bytes()

        var leading = true
        for i in 0 ..< oldBytes.count {
            if leading && oldBytes[i] == 0x00 {
                continue
            }
            leading = false
            bytes.append(oldBytes[i])
        }

        return bytes
    }
}
struct ValidationResponse: Content {
    var success: Bool
}
struct DownloadResponse: Content {
    var canBuy: Bool
    var owns: Bool
    var url:String?
}

@available(macOS 12, *)
struct FileController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes
        group.get(":tokenId", use: self.getFile)
        group.get(["download", ":tokenId"], use: self.download)
        group.get(["checkPurchase", ":transactionHash", ":tokenId"], use: self.checkPurchase)
    }
    
    func getFile(_ req: Request) async throws -> FullUploadResponse {
        let blockchain = try req.query.get(String.self, at: "blockchain")
        
        if let code = req.parameters.get("tokenId") {
            if let upload = try await Upload.query(on: req.db).filter(\.$blockchain == blockchain).filter(\.$tokenId == code).first() {
                print("upload: ", upload)
                return FullUploadResponse(upload)
            }
        }
        throw Abort(.badRequest, reason: "Cannot load it.")
    }
    
    /*
     This function updates our database with the latest from the blockchain. Our database is defacto just a cache of the blockchain.
     */
    func updateToken(_ upload: Upload, on req: Request) async throws -> Upload {
        let url = String.getAlchemyApiUrl(upload.blockchain)
        let web3 = Web3(rpcURL: url)
        let contractAddress = EthereumAddress(hexString: String.getBlockfilesSmartContractAddress(upload.blockchain))
        let accessContractAddress = EthereumAddress(hexString: String.getBlockfilesAccessSmartContractAddress(upload.blockchain))
        let contract = try web3.eth.Contract(json: String.getBlockfilesAbiData(), abiKey: nil, address: contractAddress)
       
        let parameters: [AnyObject] = [upload.tokenId!] as [AnyObject]
        let id: Int = Int(upload.tokenId!)!
        var fee: Double = 0
        var maxHolders = 0
        var downloads = 0
        try await withCheckedThrowingContinuation { continuation in
            contract["getRoyaltyFee"]?(id).call() { a, b in
                if let r = a {
                    let str = "\(r[""]!)"
                    
                    fee = Double(BigInt(str)!/1000000000)/Double(1000000000)
                    continuation.resume()
                }
            }
        }
        try await withCheckedThrowingContinuation { continuation in
            contract["getMaxHolders"]?(id).call() { a, b in
                if let r = a {
                    let str = "\(r[""]!)"
                    
                    maxHolders = Int(str)!
                    continuation.resume()
                }
            }
        }
        let accessContract = try web3.eth.Contract(json: String.getBlockfilesAccessAbiData(), abiKey: nil, address: accessContractAddress)
        try await withCheckedThrowingContinuation { continuation in
            accessContract["totalSupply"]?(id).call() { a, b in
                if let r = a {
                    let str = "\(r[""]!)"
                    
                    downloads = Int(str)!
                    continuation.resume()
                }
            }
        }
        upload.royaltyFee = fee
        upload.maxHolders = maxHolders
        upload.downloads = downloads
        try await upload.save(on: req.db)
       
        return upload
    }

    func stringToBytes(_ string: String) -> [UInt8]? {
        let length = string.count
        if length & 1 != 0 {
            return nil
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(length/2)
        var index = string.startIndex
        for _ in 0..<length/2 {
            let nextIndex = string.index(index, offsetBy: 2)
            if let b = UInt8(string[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                return nil
            }
            index = nextIndex
        }
        return bytes
    }
    func download(_ req: Request) async throws -> DownloadResponse {
        let blockchain = try req.query.get(String.self, at: "blockchain")
        if let code = req.parameters.get("tokenId") {
            
            if let upload = try await Upload.query(on: req.db).filter(\.$tokenId == code).filter(\.$blockchain == blockchain).first() {
                let url = String.getAlchemyApiUrl(upload.blockchain)
                let web3 = Web3(rpcURL: url)
                
                let realUpload = try await self.updateToken(upload, on: req)
                var allowedToDownload = false
                var canBuy = false
                var owns = false
                if realUpload.royaltyFee == 0 {
                    allowedToDownload = true
                }
                else {
                    let sign = ((try? req.query.get(at: "sign")) ?? "").replacingOccurrences(of: "0x", with: "")
                    let t = ((try? req.query.get(at: "t")) ?? "")
                    
                    if sign == "" || t == "" {
                        throw Abort(.badRequest, reason: "Please verify through your wallet.")
                    }
                    
                    let rString = String(sign.prefix(64))
                    let bytes1: [UInt8] = stringToBytes(rString)!
                    let r1 = EthereumQuantity(bytes1)
                    let sString = String(String(sign.suffix(sign.count-64)).prefix(64))
                    let bytes2: [UInt8] = stringToBytes(sString)!
                    let s1 = EthereumQuantity(bytes2)
                    let v = UInt64(String(sign.suffix(2)), radix: 16)!-27
                    //let vString = "\(v)".makeBytes()
                    let v1 = EthereumQuantity(v.makeBytes())
                    var msg = "Hi from blockfiles.io!\n\nYou sign this message so we can authenticate your address.\n\n\nTime:\(t)"
                    
                    let str = "\u{19}Ethereum Signed Message:\n\(msg.count)\(msg)"
                    let bytes = str.makeBytes()
                    
                    let k = try EthereumPublicKeyCustom(message: bytes, v: v1, r: r1, s: s1)
                    let ethAddress:String = k.address.hex(eip55: false)
                    
                    let accessContractAddress = EthereumAddress(hexString: String.getBlockfilesAccessSmartContractAddress(upload.blockchain))
                    let accessContract = try web3.eth.Contract(json: String.getBlockfilesAccessAbiData(), abiKey: nil, address: accessContractAddress)
                    var holdsAccessTokens = 0
                    try await withCheckedThrowingContinuation { continuation in
                        let tid:Int = Int(upload.tokenId!)!
                        accessContract["balanceOf"]?(k.address, tid).call() { a, b in
                            if let r = a {
                                let str = "\(r[""]!)"
                                holdsAccessTokens = Int(str)!
                                continuation.resume()
                            }
                        }
                    }
                    owns = holdsAccessTokens > 0
                    
                }
                if owns {
                    allowedToDownload = true
                }
                if upload.maxHolders > 0 {
                    if upload.downloads < upload.maxHolders {
                        canBuy = true
                    }
                }
                else {
                    canBuy = true
                }
                var signedURL:String? = nil
                if allowedToDownload {
                    let cred = try await req.application.awsClient.credentialProvider.getCredential(on: req.eventLoop, logger: req.logger).get()
                    let signer = AWSSigner(credentials: cred, name: "s3", region: "us-east-1")
                    let url = URL(string: "https://s3.amazonaws.com/final.blockfiles.io/\(upload.key)")!
                    let s3 = S3(client: req.application.awsClient)
                    //var headers = HTTPHeaders()
                    let fn = upload.name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                    //headers.replaceOrAdd(name: "response-content-disposition", value: "attachment;filename=\"\(fn)\"")
                    signedURL = signer.signURL(url: url, method: .GET, expires: .minutes(60)).absoluteString// + "&response-content-disposition=attachment;filename=\"\(fn)\""
                    
                }
                return DownloadResponse(canBuy: canBuy, owns: owns, url: signedURL)
            }
        }
        throw Abort(.badRequest, reason: "Cannot load it.")
    }
    func checkPurchase(_ req: Request) async throws -> ValidationResponse {
        let blockchain = try req.query.get(String.self, at: "blockchain")
        if let transactionHash = req.parameters.get("transactionHash"), let tokenId = req.parameters.get("tokenId") {
            if let upload = try await Upload.query(on: req.db).filter(\.$tokenId == tokenId).filter(\.$blockchain == blockchain).first() {
                let processed = try await validateAccess(upload: upload, transactionTx: transactionHash, on: req)
                return ValidationResponse(success: processed)
            }
        }
        throw Abort(.badRequest, reason: "Cannot load it.")
    }
    
    func validateAccess(upload: Upload, transactionTx: String, on req: Request) async throws -> Bool {
        // step 0: make sure we have not ever used this transaction before
        let uploads = try await Access.query(on: req.db).filter(\.$transactionTx == transactionTx).filter(\.$blockchain == upload.blockchain).count()
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
        let input = AlchemyRequest(params: [transactionTx], method: "eth_getTransactionByHash")
        let inputString = String(data: try JSONEncoder().encode(input), encoding: .utf8)!
        let res1 = try await req.client.post("\(url)", beforeSend: { r in
            r.body = ByteBufferAllocator().buffer(capacity: inputString.count)
            r.body?.writeString(inputString)
        })
        let res = try res1.content.decode(AlchemyTransactionResponse.self)
        let web3 = Web3(rpcURL: url)
        let parsed = try web3.eth.abi.decodeParameters([
            SolidityFunctionParameter(name: "tokenId", type: .uint256),
            SolidityFunctionParameter(name: "owner", type: .address)
            
        ], from: String(res.result.input.suffix(res.result.input.count-10)))
        let adr = parsed["owner"] as! EthereumAddress
        let tokenId = parsed["tokenId"] as! BigUInt
        let ownerAddress = adr.hex(eip55: true)
        
        // step 2: get transfers for this transaction
        struct AlchemyTransferResponse: Codable {
            struct Result: Codable {
                struct Transfer: Codable {
                    struct Erc1155Metadata: Codable {
                        var tokenId: String
                    }
                    var blockNum: String
                    var hash: String
                    var from: String
                    var to: String
                    var erc1155Metadata: [Erc1155Metadata]?
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
                    String.getBlockfilesAccessSmartContractAddress(upload.blockchain)
                ],
                category: ["erc1155"])
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
        for transfer in transfers {
            if transfer.from.lowercased() == "0x0000000000000000000000000000000000000000" &&
                transfer.to.lowercased() == ownerAddress.lowercased() &&
                transfer.hash.lowercased() == transactionTx.lowercased() &&
                transfer.blockNum.lowercased() == res.result.blockNumber.lowercased() &&
                transfer.erc1155Metadata != nil &&
                transfer.erc1155Metadata!.count > 0 &&
                transfer.erc1155Metadata![0].tokenId.hexaToDecimal == Int(upload.tokenId!)!
            {
                validTransaction = true
            }
        }
        if validTransaction {
            let access = Access()
            access.tokenId = upload.tokenId!
            access.transactionTx = transactionTx
            access.uploadTokenId = upload.tokenId!
            access.blockchain = upload.blockchain
            try await access.save(on: req.db)
            return true
        }
        else {
            print("f: ", transfers)
        }
        return false
    }
    
   

}
