import Fluent
import Vapor

@available(macOS 12, *)
public func routes(_ app: Application) throws {
    let root = app.grouped(.anything)

    root.get("health") { _ in
        "All good!"
    }


    try root.grouped("uploads").register(collection: UploadController())
}
