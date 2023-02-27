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

    @Field(key: "userId")
    var userId: Int

    @Field(key: "key")
    var key: String

    @Field(key: "calls")
    var calls: Int

    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?

    @Field(key: "lastUpdateAt")
    var lastUpdateAt: Date?
}
