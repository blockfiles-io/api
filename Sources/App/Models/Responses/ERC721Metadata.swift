//
//  File.swift
//  
//
//  Created by Ralph Küpper on 3/7/23.
//

import Vapor

public struct ERC721Metadata: Content {
    struct Attribute: Content {
        enum Value: Codable {
            case int(Int), string(String), bool(Bool)

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case let .int(i):
                    try container.encode(i)
                case let .string(s):
                    try container.encode(s)
                case let .bool(b):
                    try container.encode(b)
                }
            }

            init(from decoder: Decoder) throws {
                if let int = try? decoder.singleValueContainer().decode(Int.self) {
                    self = .int(int)
                    return
                }

                if let string = try? decoder.singleValueContainer().decode(String.self) {
                    self = .string(string)
                    return
                }
                if let string = try? decoder.singleValueContainer().decode(Bool.self) {
                    self = .bool(string)
                    return
                }

                self = .string("")

            }

            var stringValue: String {
                switch self {
                case let .string(string):
                    return string
                case let .bool(bool):
                    return "\(bool)"
                case let .int(int):
                    return "\(int)"
                }
            }
        }
        var trait_type: String
        var value: Value
    }
    var name: String
    var description: String
    var external_url: String?
    var image: String?
    var attributes: [Attribute]?
}
