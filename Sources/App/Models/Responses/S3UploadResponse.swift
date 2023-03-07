//
//  S3UploadResponse.swift
//  
//
//  Created by Ralph Küpper on 3/7/23.
//

import Vapor

public struct S3UploadResponse: Content {
    var size:Int64
    var sizeInMb: Int64
    
    init(size: Int64) {
        self.size = size
        self.sizeInMb = (size / 1000000) + 1
    }
}
