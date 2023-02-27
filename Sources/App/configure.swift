import Fluent
import FluentMySQLDriver
import SotoS3
import Vapor

@available(macOS 12, *)
public extension Application {

    struct AWSClientContainer {
        private final class Storage {
            let accessKey: String
            let secretKey: String
            public var client: AWSClient?

            init(accessKey: String, secretKey: String) {
                self.accessKey = accessKey
                self.secretKey = secretKey
            }
        }

        private struct Key: StorageKey {
            typealias Value = Storage
        }

        private var storage: Storage {
            if self.application.storage[Key.self] == nil {
                self.initialize()
            }
            return self.application.storage[Key.self]!
        }

        public func initialize() {
            guard
                let awsAccessKey = Environment.process.AWS_ACCESS_KEY1
            else {
                fatalError("No value was found at the given public key environment 'AWS_ACCESS_KEY1'")
            }
            guard
                let awsAccessSecret = Environment.process.AWS_ACCESS_SECRET1
            else {
                fatalError("No value was found at the given public key environment 'AWS_ACCESS_SECRET1'")
            }

            self.application.storage[Key.self] = .init(accessKey: awsAccessKey, secretKey: awsAccessSecret)
        }

        fileprivate let application: Application

        init(application: Application) {
            self.application = application
            self.initialize()
            self.application.storage[Key.self]!.client = .init(credentialProvider: .static(accessKeyId: self.storage.accessKey, secretAccessKey: self.storage.secretKey), httpClientProvider: .createNew)
        }

        var client: AWSClient {
            self.application.storage[Key.self]!.client!
        }
    }

    var awsClientContainer: AWSClientContainer { AWSClientContainer(application: self) }
    

}

// Called before your application initializes.
@available(macOS 12, *)
public func configure(_ app: Application) throws {

    guard
        let urlString = Environment.process.MYSQL_CRED
    else {
        fatalError("No value was found at the given public key environment 'MYSQL_CRED'")
    }
    let environmentInput = Environment.process.ENVIRONMENT

    guard
        let awsAccessKey = Environment.process.AWS_ACCESS_KEY1
    else {
        fatalError("No value was found at the given public key environment 'AWS_ACCESS_KEY1'")
    }
    guard
        let awsAccessSecret = Environment.process.AWS_ACCESS_SECRET1
    else {
        fatalError("No value was found at the given public key environment 'AWS_ACCESS_SECRET1'")
    }
    
    guard
        let url = URL(string: urlString)
    else {
        fatalError("Cannot parse: \(urlString) correctly.")
    }

    do {
        app.databases.use(try .mysql(url: url, maxConnectionsPerEventLoop: 100), as: .mysql)
    } catch {
        print("error: ", error)
    }
    app.middleware.use(CORSMiddleware(configuration: .init(allowedOrigin: .all, allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH], allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith])))

    
    try routes(app)
}
