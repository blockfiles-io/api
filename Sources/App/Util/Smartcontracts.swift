//
//  File.swift
//  
//
//  Created by Ralph Küpper on 3/6/23.
//

import Vapor

extension String {
    static var ARB_GOERLI_BLOCKFILES = "0x91CCb03f4c965831399F1915c178cb5853FfAD6e"
    static var ARB_GOERLI_BLOCKFILESACCESS = "0xf29284ac9f9a0f381e08d8907b8ca90683e421ed"
    static var ETH_GOERLI_BLOCKFILES = "0xFD6FaF04156D9392EB1D05f092c2D00A9FA5E63F"
    static var ETH_GOERLI_BLOCKFILESACCESS = "0x37fe0aC287B8c061cf1cb3a886E1BF17b89a658A"
    static var OPT_GOERLI_BLOCKFILES = "0x5e41CcC3599785AA5F66dfc3da6cD1f9C8e64D63"
    static var OPT_GOERLI_BLOCKFILESACCESS = "0x2bE78D8befea0D091b144C60CCcBb224D435A4c2"
    static var SPH_SPHINX_BLOCKFILES = "0x7d57b63596d347fcc0801b1ce3fc5c1e8d82324d"
    static var SPH_SPHINX_BLOCKFILESACCESS = "0x5e41ccc3599785aa5f66dfc3da6cd1f9c8e64d63"
    static var MAT_MUMBAI_BLOCKFILES = "0x5e41CcC3599785AA5F66dfc3da6cD1f9C8e64D63"
    static var MAT_MUMBAI_BLOCKFILESACCESS = "0x2bE78D8befea0D091b144C60CCcBb224D435A4c2"
    static var BASE_GOERLI_BLOCKFILES = "0x5e41CcC3599785AA5F66dfc3da6cD1f9C8e64D63"
    static var BASE_GOERLI_BLOCKFILESACCESS = "0x2bE78D8befea0D091b144C60CCcBb224D435A4c2"
    static var MAT_BLOCKFILES = "0x5e41CcC3599785AA5F66dfc3da6cD1f9C8e64D63"
    static var MAT_BLOCKFILESACCESS = "0x37fe0aC287B8c061cf1cb3a886E1BF17b89a658A"
    static var ARB_BLOCKFILES = "0x5e41CcC3599785AA5F66dfc3da6cD1f9C8e64D63"
    static var ARB_BLOCKFILESACCESS = "0x2bE78D8befea0D091b144C60CCcBb224D435A4c2"
    static var ETH_BLOCKFILES = ""
    static var ETH_BLOCKFILESACCESS = ""
    static var OPT_BLOCKFILES = "0x5e41CcC3599785AA5F66dfc3da6cD1f9C8e64D63"
    static var OPT_BLOCKFILESACCESS = "0x2bE78D8befea0D091b144C60CCcBb224D435A4c2"
    static var BASE_BLOCKFILES = ""
    static var BASE_BLOCKFILESACCESS = ""
    
    static func getBlockfilesSmartContractAddress(_ network: String) -> String {
        if network == "arbGoerli" {
            return String.ARB_GOERLI_BLOCKFILES
        }
        else if network == "optGoerli" {
            return String.OPT_GOERLI_BLOCKFILES
        }
        else if network == "goerli" {
            return String.ETH_GOERLI_BLOCKFILES
        }
        else if network == "sphinx" {
            return String.SPH_SPHINX_BLOCKFILES
        }
        else if network == "mumbai" {
            return String.MAT_MUMBAI_BLOCKFILES
        }
        else if network == "baseGoerli" {
            return String.BASE_BLOCKFILES
        }
        else if network == "polygon" {
            return String.MAT_BLOCKFILES
        }
        else if network == "arbitrum" {
            return String.ARB_BLOCKFILES
        }
        else if network == "optimism" {
            return String.OPT_BLOCKFILES
        }
        else if network == "ethereum" {
            return String.ETH_BLOCKFILES
        }
        return ""
    }
    static func getBlockfilesAccessSmartContractAddress(_ network: String) -> String {
        if network == "arbGoerli" {
            return String.ARB_GOERLI_BLOCKFILESACCESS
        }
        else if network == "optGoerli" {
            return String.OPT_GOERLI_BLOCKFILESACCESS
        }
        else if network == "goerli" {
            return String.ETH_GOERLI_BLOCKFILESACCESS
        }
        else if network == "sphinx" {
            return String.SPH_SPHINX_BLOCKFILESACCESS
        }
        else if network == "mumbai" {
            return String.MAT_MUMBAI_BLOCKFILESACCESS
        }
        else if network == "baseGoerli" {
            return String.BASE_BLOCKFILESACCESS
        }
        else if network == "polygon" {
            return String.MAT_BLOCKFILESACCESS
        }
        else if network == "arbitrum" {
            return String.ARB_BLOCKFILESACCESS
        }
        else if network == "optimism" {
            return String.OPT_BLOCKFILESACCESS
        }
        else if network == "ethereum" {
            return String.ETH_BLOCKFILESACCESS
        }
        return ""
    }
    
    static func getAlchemyApiUrl(_ network: String) -> String {
        if network == "arbGoerli" {
            if let url = Environment.process.ARB_GOERLI_API {
                return url
            }
        }
        else if network == "optGoerli" {
            if let url = Environment.process.OPT_GOERLI_API {
                return url
            }
        }
        else if network == "goerli" {
            if let url = Environment.process.ETH_GOERLI_API {
                return url
            }
        }
        else if network == "sphinx" {
            if let url = Environment.process.SPH_SPHINX_API {
                return url
            }
        }
        else if network == "mumbai" {
            if let url = Environment.process.MATIC_MUMBAI_API {
                return url
            }
        }
        else if network == "baseGoerli" {
            if let url = Environment.process.BASE_GOERLI_API {
                return url
            }
        }
        else if network == "polygon" {
            if let url = Environment.process.MATIC_API {
                return url
            }
        }
        else if network == "arbitrum" {
            if let url = Environment.process.ARB_API {
                return url
            }
        }
        else if network == "optimism" {
            if let url = Environment.process.OPT_API {
                return url
            }
        }
        else if network == "ethereum" {
            if let url = Environment.process.ETH_API {
                return url
            }
        }
        return ""
    }
    
    static func getBlockfilesAccessAbiData() -> Data {
        let abi = """
        [{
              "inputs": [
                {
                  "internalType": "address",
                  "name": "account",
                  "type": "address"
                },
                {
                  "internalType": "uint256",
                  "name": "id",
                  "type": "uint256"
                }
              ],
              "name": "balanceOf",
              "outputs": [
                {
                  "internalType": "uint256",
                  "name": "",
                  "type": "uint256"
                }
              ],
              "stateMutability": "view",
              "type": "function"
            },
        {
              "inputs": [
                {
                  "internalType": "uint256",
                  "name": "id",
                  "type": "uint256"
                }
              ],
              "name": "totalSupply",
              "outputs": [
                {
                  "internalType": "uint256",
                  "name": "",
                  "type": "uint256"
                }
              ],
              "stateMutability": "view",
              "type": "function"
            }
        ]
        
        """
        return abi.data(using: .utf8)!
    }
    
    static func getBlockfilesAbiData() -> Data {
        let abi = """
[
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "owner",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "approved",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "uint256",
          "name": "tokenId",
          "type": "uint256"
        }
      ],
      "name": "Approval",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "owner",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "operator",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "bool",
          "name": "approved",
          "type": "bool"
        }
      ],
      "name": "ApprovalForAll",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint8",
          "name": "version",
          "type": "uint8"
        }
      ],
      "name": "Initialized",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "owner",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "tokenId",
          "type": "uint256"
        }
      ],
      "name": "NewFileMinted",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "previousOwner",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "newOwner",
          "type": "address"
        }
      ],
      "name": "OwnershipTransferred",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "from",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "to",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "uint256",
          "name": "tokenId",
          "type": "uint256"
        }
      ],
      "name": "Transfer",
      "type": "event"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "to",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "tokenId",
          "type": "uint256"
        }
      ],
      "name": "approve",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "owner",
          "type": "address"
        }
      ],
      "name": "balanceOf",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "tokenId",
          "type": "uint256"
        }
      ],
      "name": "getApproved",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getFreeFilesFee",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "tokenId",
          "type": "uint256"
        }
      ],
      "name": "getMaxHolders",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "tokenId",
          "type": "uint256"
        }
      ],
      "name": "getRoyaltyFee",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "initialize",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "owner",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "operator",
          "type": "address"
        }
      ],
      "name": "isApprovedForAll",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "sizeInMB",
          "type": "uint256"
        },
        {
          "internalType": "address",
          "name": "owner",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "maxHolders",
          "type": "uint256"
        },
        {
          "internalType": "uint256",
          "name": "royaltyFee",
          "type": "uint256"
        }
      ],
      "name": "mint",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "name",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "owner",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "tokenId",
          "type": "uint256"
        }
      ],
      "name": "ownerOf",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "renounceOwnership",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "from",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "to",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "tokenId",
          "type": "uint256"
        }
      ],
      "name": "safeTransferFrom",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "from",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "to",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "tokenId",
          "type": "uint256"
        },
        {
          "internalType": "bytes",
          "name": "data",
          "type": "bytes"
        }
      ],
      "name": "safeTransferFrom",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "operator",
          "type": "address"
        },
        {
          "internalType": "bool",
          "name": "approved",
          "type": "bool"
        }
      ],
      "name": "setApprovalForAll",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "newSplit",
          "type": "uint256"
        }
      ],
      "name": "setDevSplit",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "fee",
          "type": "uint256"
        }
      ],
      "name": "setFreeFilesFee",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "newPrice",
          "type": "uint256"
        }
      ],
      "name": "setPricePerMB",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "open",
          "type": "uint256"
        }
      ],
      "name": "setUploadOpen",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "newSplit",
          "type": "uint256"
        }
      ],
      "name": "setWhistleblowerSplit",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "bytes4",
          "name": "interfaceId",
          "type": "bytes4"
        }
      ],
      "name": "supportsInterface",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "symbol",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "index",
          "type": "uint256"
        }
      ],
      "name": "tokenByIndex",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "owner",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "index",
          "type": "uint256"
        }
      ],
      "name": "tokenOfOwnerByIndex",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "tokenId",
          "type": "uint256"
        }
      ],
      "name": "tokenURI",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "totalSupply",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "from",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "to",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "tokenId",
          "type": "uint256"
        }
      ],
      "name": "transferFrom",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "newOwner",
          "type": "address"
        }
      ],
      "name": "transferOwnership",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "withdraw",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    }
  ]
"""
        return abi.data(using: .utf8)!
    }
}
