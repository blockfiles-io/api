//
//  BlogController.swift
//
//
//  Created by Ralph Küpper on 02/27/2023.
//

import Fluent
import Vapor

@available(macOS 12, *)
struct UploadController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes
        group.post("getSignedUrl", use: self.getSignedUrl)
    }

    func getSignedUrl(_ req: Request) async throws -> HTTPStatus {
        return .ok
    }

}
