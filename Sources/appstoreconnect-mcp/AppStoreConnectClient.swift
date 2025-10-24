import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging

/// Errors specific to App Store Connect operations
enum ASCError: Error, LocalizedError {
    case authenticationFailed(String)
    case apiError(Int, String)
    case notFound(String)
    case rateLimitExceeded
    case invalidPrivateKey(String)
    case invalidBundleID(String)
    case buildNotFound(String)
    case downloadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .apiError(let code, let message):
            return "App Store Connect API error (\(code)): \(message)"
        case .notFound(let resource):
            return "Resource not found: \(resource)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .invalidPrivateKey(let message):
            return "Invalid private key: \(message)"
        case .invalidBundleID(let bundleID):
            return "Invalid bundle ID: \(bundleID)"
        case .buildNotFound(let buildID):
            return "Build not found: \(buildID)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        }
    }
}

/// Actor that wraps the App Store Connect client for thread-safe access
actor AppStoreConnectClientWrapper {
    private let client: AppStoreConnectClient
    private let logger: Logger
    
    init(keyID: String, issuerID: String, privateKeyPath: String, keyExpiry: Int) throws {
        self.logger = Logger(label: "asc-client")
        
        // Load private key
        let keyURL = URL(filePath: privateKeyPath)
        guard FileManager.default.fileExists(atPath: privateKeyPath) else {
            logger.error("Private key file not found", metadata: ["path": "\(privateKeyPath)"])
            throw ASCError.invalidPrivateKey("File not found at path: \(privateKeyPath)")
        }
        
        let privateKey: JWT.PrivateKey
        do {
            privateKey = try JWT.PrivateKey(contentsOf: keyURL)
        } catch {
            logger.error("Failed to load private key", metadata: ["error": "\(error)"])
            throw ASCError.invalidPrivateKey(error.localizedDescription)
        }
        
        // Create authenticator
        let authenticator = JWT(
            keyID: keyID,
            issuerID: issuerID,
            expiryDuration: TimeInterval(keyExpiry),
            privateKey: privateKey
        )
        
        // Create client
        self.client = AppStoreConnectClient(authenticator: authenticator)
        
        logger.info("App Store Connect client initialized successfully")
    }
    
    /// List all apps with optional bundle ID filter
    func listApps(bundleIDFilter: String? = nil) async throws -> [App] {
        do {
            let response = try await client.send(
                Resources.v1.apps.get(
                    filterBundleID: bundleIDFilter.map { [$0] }
                )
            )
            logger.debug("Retrieved \(response.data.count) apps")
            return response.data
        } catch {
            logger.error("Failed to list apps", metadata: ["error": "\(error)"])
            throw mapAPIError(error)
        }
    }
    
    /// Get app by ID
    func getApp(id: String) async throws -> App {
        do {
            let response = try await client.send(Resources.v1.apps.id(id).get())
            logger.debug("Retrieved app", metadata: ["id": "\(id)", "name": "\(response.data.attributes?.name ?? "unknown")"])
            return response.data
        } catch {
            logger.error("Failed to get app", metadata: ["id": "\(id)", "error": "\(error)"])
            throw mapAPIError(error)
        }
    }
    
    /// Find app by bundle ID
    func findAppByBundleID(_ bundleID: String) async throws -> App {
        let apps = try await listApps(bundleIDFilter: bundleID)
        guard let app = apps.first else {
            throw ASCError.invalidBundleID(bundleID)
        }
        return app
    }
    
    /// List builds for an app
    func listBuilds(appID: String, versionFilter: String? = nil) async throws -> [Build] {
        do {
            let response = try await client.send(
                Resources.v1.builds.get(
                    filterVersion: versionFilter.map { [$0] },
                    filterApp: [appID],
                    sort: [.minusUploadedDate]
                )
            )
            logger.debug("Retrieved \(response.data.count) builds for app", metadata: ["appID": "\(appID)"])
            return response.data
        } catch {
            logger.error("Failed to list builds", metadata: ["appID": "\(appID)", "error": "\(error)"])
            throw mapAPIError(error)
        }
    }
    
    /// Get latest build for an app
    func getLatestBuild(appID: String) async throws -> Build {
        let builds = try await listBuilds(appID: appID)
        guard let latestBuild = builds.first else {
            throw ASCError.buildNotFound("No builds found for app: \(appID)")
        }
        return latestBuild
    }
    
    /// Get build by ID
    func getBuild(id: String) async throws -> Build {
        do {
            let response = try await client.send(Resources.v1.builds.id(id).get())
            logger.debug("Retrieved build", metadata: ["id": "\(id)"])
            return response.data
        } catch {
            logger.error("Failed to get build", metadata: ["id": "\(id)", "error": "\(error)"])
            throw mapAPIError(error)
        }
    }
    
    /// Download dSYMs for a build
    func downloadDSYMs(buildID: String, outputPath: String) async throws -> URL {
        do {
            // Get build to verify it exists
            _ = try await getBuild(id: buildID)

            // Create output directory
            let outputURL = URL(filePath: outputPath)
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

            // The actual dSYM download requires the build to have processed dSYMs
            // and uses the build's dSYM URL endpoint
            let dSymPath = outputURL.appendingPathComponent("dsyms-\(buildID).zip")

            logger.info("dSYMs download prepared", metadata: ["buildID": "\(buildID)", "outputPath": "\(dSymPath.path)"])

            // Note: Full implementation would use Resources.v1.builds.id(buildID).betaBuildLocalizations
            // or similar to get the actual dSYM download URL
            // This is a placeholder showing where the file would be saved
            return dSymPath
        } catch {
            logger.error("Failed to download dSYMs", metadata: ["buildID": "\(buildID)", "error": "\(error)"])
            throw mapAPIError(error)
        }
    }
    
    /// Map API errors to custom error types
    private func mapAPIError(_ error: Error) -> Error {
        // Check for HTTP errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .userAuthenticationRequired:
                return ASCError.authenticationFailed(urlError.localizedDescription)
            case .notConnectedToInternet, .timedOut:
                return ASCError.apiError(urlError.code.rawValue, urlError.localizedDescription)
            default:
                return ASCError.apiError(urlError.code.rawValue, urlError.localizedDescription)
            }
        }
        
        // Return original error if not a known type
        return error
    }
}
