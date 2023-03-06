//
//  UploadResponse.swift
//
//
//  Created by Ralph Küpper on 02/27/2023.
//

import Vapor

public struct UploadResponse: Content {
    var url: String
    var key: String
}
