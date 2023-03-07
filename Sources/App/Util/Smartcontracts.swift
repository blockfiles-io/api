//
//  File.swift
//  
//
//  Created by Ralph Küpper on 3/6/23.
//

import Vapor

extension String {
    static var ARB_GOERLI_BLOCKFILES = "0x91CCb03f4c965831399F1915c178cb5853FfAD6e"
    static var ARB_GOERLI_BLOCKFILESACCESS = "0xFc8E2198b55e5E8B98a929847f27b8608479D13d"
    
    static func getBlockfilesSmartContractAddress(_ network: String) -> String {
        if network == "arbGoerli" {
            return String.ARB_GOERLI_BLOCKFILES
        }
        return ""
    }
    
    static func getAlchemyApiUrl(_ network: String) -> String {
        if network == "arbGoerli" {
            if let url = Environment.process.ARB_GOERLI_API {
                return url
            }
        }
        return ""
    }
}
