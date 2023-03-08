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

@available(macOS 12, *)
struct FileController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes
        group.get(":tokenId", use: self.getFile)
        group.get(["download", ":tokenId"], use: self.download)
        group.get(["checkPurchase", ":transactionHash"], use: self.checkPurchase)
    }
    
    func getFile(_ req: Request) async throws -> FullUploadResponse {
        if let code = req.parameters.get("tokenId") {
            if let upload = try await Upload.query(on: req.db).filter(\.$tokenId == code).first() {
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
    /*func bytesToString(_ hex: [UInt8]) -> String {
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
    }*/
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
    func download(_ req: Request) async throws -> HTTPStatus{
        if let code = req.parameters.get("tokenId") {
            
            if let upload = try await Upload.query(on: req.db).filter(\.$tokenId == code).first() {
                let url = String.getAlchemyApiUrl(upload.blockchain)
                let web3 = Web3(rpcURL: url)
                
                let sign = ((try? req.query.get(at: "sign")) ?? "").replacingOccurrences(of: "0x", with: "")
                let t = ((try? req.query.get(at: "t")) ?? "")
                
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
                print("key: ",k.address.hex(eip55: false))
                
                let realUpload = try await self.updateToken(upload, on: req)
                var allowedToDownload = false
                if realUpload.royaltyFee == 0 {
                    allowedToDownload = true
                }
                return .ok
            }
        }
        throw Abort(.badRequest, reason: "Cannot load it.")
    }
    func checkPurchase(_ req: Request) async throws -> HTTPStatus{
        if let code = req.parameters.get("transactionHash") {
            return .ok
            
        }
        throw Abort(.badRequest, reason: "Cannot load it.")
    }
    
   

}
