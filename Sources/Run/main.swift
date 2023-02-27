import blockfilesImpl
import Vapor
import VaporAWSLambdaRuntime

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
if #available(macOS 12, *) {
    try configure(app)
} else {
    // Fallback on earlier versions
}

#if !DEBUG

app.storage[Application.Lambda.Server.ConfigurationKey.self] = .init(apiService: .apiGatewayV2,
                                                                     logger: app.logger)
app.servers.use(.lambda)
#endif
try app.run()
