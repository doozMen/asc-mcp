import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import Subprocess

#if canImport(System)
@preconcurrency import System
#else
@preconcurrency import SystemPackage
#endif

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
      logger.debug(
        "Retrieved app",
        metadata: ["id": "\(id)", "name": "\(response.data.attributes?.name ?? "unknown")"])
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
      logger.debug(
        "Retrieved \(response.data.count) builds for app", metadata: ["appID": "\(appID)"])
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

  /// Get build by ID with build bundles included
  func getBuild(id: String, includeBuildBundles: Bool = false) async throws -> BuildResponse {
    do {
      let response = try await client.send(
        Resources.v1.builds
          .id(id)
          .get(include: includeBuildBundles ? [.buildBundles] : nil)
      )
      logger.debug(
        "Retrieved build",
        metadata: ["id": "\(id)", "includedCount": "\(response.included?.count ?? 0)"])
      return response
    } catch {
      logger.error("Failed to get build", metadata: ["id": "\(id)", "error": "\(error)"])
      throw mapAPIError(error)
    }
  }

  /// Download dSYMs for a build from App Store Connect
  ///
  /// Downloads the dSYM files as a ZIP archive from the App Store Connect API and extracts them.
  ///
  /// - Parameters:
  ///   - buildID: The App Store Connect build ID
  ///   - outputPath: Directory where dSYMs should be extracted
  /// - Returns: URL to the directory containing extracted dSYM files
  /// - Throws: ASCError if the build is not found, dSYM URL is unavailable, or download fails
  func downloadDSYMs(buildID: String, outputPath: String) async throws -> URL {
    logger.debug(
      "Downloading dSYMs", metadata: ["buildID": "\(buildID)", "outputPath": "\(outputPath)"])

    do {
      // 1. Get build with buildBundles included
      let buildResponse = try await getBuild(id: buildID, includeBuildBundles: true)
      let build = buildResponse.data

      // Verify the build has been processed
      guard let processingState = build.attributes?.processingState else {
        throw ASCError.downloadFailed("Build processing state is unknown for build \(buildID)")
      }

      guard processingState == .valid else {
        throw ASCError.downloadFailed(
          "Build must be in VALID state to have dSYMs. Current state: \(processingState.rawValue)")
      }

      // 2. Extract dSYM URL from build bundles
      guard let included = buildResponse.included else {
        throw ASCError.downloadFailed("No included data in build response for build \(buildID)")
      }

      // Find BuildBundle items in included data
      let buildBundles = included.compactMap { item -> BuildBundle? in
        if case .buildBundle(let bundle) = item {
          return bundle
        }
        return nil
      }

      guard !buildBundles.isEmpty else {
        throw ASCError.downloadFailed("No build bundles available for build \(buildID)")
      }

      // Find the first bundle with a dSYM URL
      guard
        let dSYMUrl = buildBundles.first(where: { $0.attributes?.dSYMURL != nil })?.attributes?
          .dSYMURL
      else {
        throw ASCError.downloadFailed(
          "No dSYM URL available for build \(buildID). The build may not include symbols or symbols may not be available yet."
        )
      }

      logger.info(
        "Found dSYM URL", metadata: ["buildID": "\(buildID)", "url": "\(dSYMUrl.absoluteString)"])

      // 3. Download dSYM ZIP file with URLSession
      logger.debug("Downloading dSYM ZIP from URL", metadata: ["url": "\(dSYMUrl.absoluteString)"])
      let (tempURL, response) = try await URLSession.shared.download(from: dSYMUrl)

      guard let httpResponse = response as? HTTPURLResponse,
        (200...299).contains(httpResponse.statusCode)
      else {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        throw ASCError.downloadFailed("HTTP error downloading dSYM: status code \(statusCode)")
      }

      // 4. Create output directory and move ZIP file
      let outputURL = URL(filePath: outputPath)
      try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

      let zipPath = outputURL.appendingPathComponent("dsyms-\(buildID).zip")
      if FileManager.default.fileExists(atPath: zipPath.path) {
        try FileManager.default.removeItem(at: zipPath)
      }
      try FileManager.default.moveItem(at: tempURL, to: zipPath)

      let zipSize =
        try FileManager.default.attributesOfItem(atPath: zipPath.path)[.size] as? Int ?? 0
      logger.debug(
        "Downloaded dSYM ZIP", metadata: ["zipPath": "\(zipPath.path)", "size": "\(zipSize)"])

      // 5. Unzip dSYM files using system unzip command
      let dsymDir = outputURL.appendingPathComponent("dSYMs")
      if FileManager.default.fileExists(atPath: dsymDir.path) {
        try FileManager.default.removeItem(at: dsymDir)
      }
      try FileManager.default.createDirectory(at: dsymDir, withIntermediateDirectories: true)

      logger.debug(
        "Extracting dSYM files",
        metadata: ["zipPath": "\(zipPath.path)", "destination": "\(dsymDir.path)"])

      // Use unzip command to extract
      let result = try await Subprocess.run(
        .path(FilePath("/usr/bin/unzip")),
        arguments: ["-q", zipPath.path, "-d", dsymDir.path],
        output: .string(limit: .max),
        error: .string(limit: .max)
      )

      // Log any output for debugging
      if let output = result.standardOutput, !output.isEmpty {
        logger.trace("unzip output", metadata: ["output": "\(output)"])
      }
      if let error = result.standardError, !error.isEmpty {
        logger.trace("unzip error", metadata: ["error": "\(error)"])
      }

      guard result.terminationStatus.isSuccess else {
        let errorMessage = result.standardError ?? "Unknown error"
        throw ASCError.downloadFailed("Failed to unzip dSYM files: \(errorMessage)")
      }

      // 6. Clean up ZIP file
      try FileManager.default.removeItem(at: zipPath)

      logger.info(
        "Successfully downloaded and extracted dSYMs",
        metadata: [
          "buildID": "\(buildID)",
          "version": "\(build.attributes?.version ?? "unknown")",
          "dsymDirectory": "\(dsymDir.path)",
        ])

      return dsymDir
    } catch let error as ASCError {
      logger.error(
        "Failed to download dSYMs",
        metadata: ["buildID": "\(buildID)", "error": "\(error.localizedDescription)"])
      throw error
    } catch {
      logger.error(
        "Failed to download dSYMs", metadata: ["buildID": "\(buildID)", "error": "\(error)"])
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
