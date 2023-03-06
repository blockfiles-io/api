//
//  File.swift
//  
//
//  Created by Ralph Küpper on 3/6/23.
//

import Vapor

extension String {
    static var ARB_GOERLI_BLOCKFILES = "0xDf5D8e7380f9f8aD4038C5b07c156C3E103fe5D7"
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
