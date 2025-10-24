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
    ///
    /// Note: The App Store Connect API does not provide a direct endpoint to download dSYM files.
    /// This method verifies the build exists and provides information about alternative methods.
    ///
    /// Alternative methods to download dSYMs:
    /// 1. Use Xcode Organizer (Window > Organizer > Archives)
    /// 2. Download from App Store Connect web portal (TestFlight > Build > Download dSYM)
    /// 3. Use Fastlane: `fastlane run download_dsyms`
    /// 4. Use Xcode command line: `xcodebuild -exportArchive -archivePath <path> -exportPath <path>`
    ///
    /// - Parameters:
    ///   - buildID: The App Store Connect build ID
    ///   - outputPath: Directory where dSYM information should be saved
    /// - Returns: URL to the information file about dSYM download methods
    /// - Throws: ASCError if the build is not found or API errors occur
    func downloadDSYMs(buildID: String, outputPath: String) async throws -> URL {
        logger.debug("Attempting dSYM download", metadata: ["buildID": "\(buildID)", "outputPath": "\(outputPath)"])

        do {
            // Get build to verify it exists and collect metadata
            let build = try await getBuild(id: buildID)

            // Verify the build has been processed
            guard let processingState = build.attributes?.processingState else {
                throw ASCError.downloadFailed("Build processing state is unknown for build \(buildID)")
            }

            guard processingState == .valid else {
                throw ASCError.downloadFailed("Build must be in VALID state to have dSYMs. Current state: \(processingState.rawValue)")
            }

            // Create output directory
            let outputURL = URL(filePath: outputPath)
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

            // Create an information file with alternative methods
            let infoPath = outputURL.appendingPathComponent("dsym-download-info-\(buildID).txt")

            var infoContent = """
            dSYM Download Information
            =========================

            Build ID: \(buildID)
            Version: \(build.attributes?.version ?? "unknown")
            Uploaded: \(build.attributes?.uploadedDate?.description ?? "unknown")
            Processing State: \(processingState.rawValue)

            IMPORTANT: App Store Connect API Limitation
            -------------------------------------------
            The App Store Connect API does not provide a direct endpoint to download dSYM files.
            This is a known limitation of the API.

            Alternative Methods to Download dSYMs:
            --------------------------------------

            1. Xcode Organizer (Recommended for manual downloads):
               - Open Xcode
               - Window > Organizer
               - Select Archives
               - Find your build and click "Download Debug Symbols"

            2. App Store Connect Web Portal:
               - Visit https://appstoreconnect.apple.com
               - Go to TestFlight > Your App > Build \(build.attributes?.version ?? "")
               - Click "Download dSYM"

            3. Fastlane (Recommended for automation):
               Install Fastlane and run:
               fastlane run download_dsyms app_identifier:YOUR_BUNDLE_ID version:\(build.attributes?.version ?? "")

               Or add to your Fastfile:
               lane :download_symbols do
                 download_dsyms(
                   app_identifier: "YOUR_BUNDLE_ID",
                   version: "\(build.attributes?.version ?? "")"
                 )
               end

            4. Manual Archive Export:
               If you have the original Xcode archive:
               xcodebuild -exportArchive \\
                 -archivePath /path/to/YourApp.xcarchive \\
                 -exportPath /path/to/output \\
                 -exportOptionsPlist /path/to/ExportOptions.plist

            For Crash Symbolication:
            ------------------------
            Once you have the dSYM files, use them with:
            - Xcode Organizer for crash reports
            - Firebase Crashlytics upload: firebase crashlytics:symbols:upload --app=APP_ID path/to/dSYMs
            - Symbolicate manually: atos -arch arm64 -o YourApp.app.dSYM/Contents/Resources/DWARF/YourApp -l LOAD_ADDRESS STACK_ADDRESS

            """

            // Add app information if available
            if let appID = build.relationships?.app?.data?.id {
                do {
                    let app = try await getApp(id: appID)
                    if let bundleID = app.attributes?.bundleID {
                        infoContent += "\nApp Bundle ID: \(bundleID)\n"
                        infoContent += """

                        Fastlane Command for this app:
                        fastlane run download_dsyms app_identifier:\(bundleID) version:\(build.attributes?.version ?? "")

                        """
                    }
                } catch {
                    logger.warning("Could not fetch app information", metadata: ["appID": "\(appID)", "error": "\(error)"])
                }
            }

            // Write information file
            try infoContent.write(to: infoPath, atomically: true, encoding: .utf8)

            logger.info("dSYM download information created", metadata: [
                "buildID": "\(buildID)",
                "version": "\(build.attributes?.version ?? "unknown")",
                "infoPath": "\(infoPath.path)"
            ])

            return infoPath
        } catch let error as ASCError {
            logger.error("Failed to prepare dSYM download", metadata: ["buildID": "\(buildID)", "error": "\(error.localizedDescription)"])
            throw error
        } catch {
            logger.error("Failed to prepare dSYM download", metadata: ["buildID": "\(buildID)", "error": "\(error)"])
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
