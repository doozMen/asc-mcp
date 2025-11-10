import Foundation
import Logging

/// Represents a parsed Xcode archive with all relevant metadata
struct XcodeArchive: Sendable, Identifiable {
  let id: String  // Archive path
  let path: URL
  let name: String
  let bundleID: String
  let version: String
  let buildNumber: String
  let creationDate: Date
  let dsymsPath: URL

  var displayName: String {
    "\(name) v\(version) (\(buildNumber))"
  }
}

/// Errors that can occur during archive operations
enum ArchiveError: Error, LocalizedError {
  case archiveDirectoryNotFound
  case noArchivesFound(String?)
  case infoPlistNotFound(URL)
  case infoPlistInvalid(URL, String)
  case noMatchingArchives(appName: String?, bundleID: String?)

  var errorDescription: String? {
    switch self {
    case .archiveDirectoryNotFound:
      return "Xcode archives directory not found at ~/Library/Developer/Xcode/Archives"
    case .noArchivesFound(let filter):
      if let filter {
        return "No archives found matching filter: \(filter)"
      }
      return "No Xcode archives found"
    case .infoPlistNotFound(let url):
      return "Info.plist not found in archive at \(url.path)"
    case .infoPlistInvalid(let url, let reason):
      return "Invalid Info.plist in archive at \(url.path): \(reason)"
    case .noMatchingArchives(let appName, let bundleID):
      var message = "No archives found"
      if let appName {
        message += " with app name matching '\(appName)'"
      }
      if let bundleID {
        if appName != nil {
          message += " and"
        }
        message += " with bundle ID matching '\(bundleID)'"
      }
      return message
    }
  }
}

/// Actor responsible for finding and parsing Xcode archives
actor ArchiveFinder {
  private let logger: Logger
  private let archivesDirectory: URL

  /// Initialize the archive finder
  /// - Parameter logger: Logger instance for diagnostic messages
  init(logger: Logger) {
    self.logger = logger
    self.archivesDirectory = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/Developer/Xcode/Archives")
  }

  /// Find all archives matching the given filters
  /// - Parameters:
  ///   - appNameFilter: Optional case-insensitive partial match for app name
  ///   - bundleIDFilter: Optional case-insensitive partial match for bundle ID
  /// - Returns: Array of matching archives, sorted by creation date (newest first)
  /// - Throws: ArchiveError if directory not found or no archives found
  func findArchives(
    appNameFilter: String? = nil,
    bundleIDFilter: String? = nil
  ) async throws -> [XcodeArchive] {
    logger.info(
      "Searching for archives",
      metadata: [
        "appNameFilter": .string(appNameFilter ?? "none"),
        "bundleIDFilter": .string(bundleIDFilter ?? "none"),
        "directory": .string(archivesDirectory.path),
      ])

    // Verify archives directory exists
    guard FileManager.default.fileExists(atPath: archivesDirectory.path) else {
      logger.error(
        "Archives directory not found",
        metadata: [
          "path": .string(archivesDirectory.path)
        ])
      throw ArchiveError.archiveDirectoryNotFound
    }

    // Find all .xcarchive directories
    let archivePaths = try findAllArchivePaths()

    guard !archivePaths.isEmpty else {
      logger.warning("No archives found in directory")
      throw ArchiveError.noArchivesFound(nil)
    }

    logger.info("Found \(archivePaths.count) archive(s)")

    // Parse each archive
    var archives: [XcodeArchive] = []
    for path in archivePaths {
      do {
        let archive = try parseArchive(at: path)

        // Apply filters
        if let appNameFilter, !archive.name.localizedCaseInsensitiveContains(appNameFilter) {
          continue
        }

        if let bundleIDFilter, !archive.bundleID.localizedCaseInsensitiveContains(bundleIDFilter) {
          continue
        }

        archives.append(archive)
      } catch {
        logger.warning(
          "Failed to parse archive",
          metadata: [
            "path": .string(path.path),
            "error": .string(String(describing: error)),
          ])
        // Continue parsing other archives
      }
    }

    guard !archives.isEmpty else {
      throw ArchiveError.noMatchingArchives(appName: appNameFilter, bundleID: bundleIDFilter)
    }

    // Sort by creation date (newest first)
    let sortedArchives = archives.sorted { $0.creationDate > $1.creationDate }

    logger.info("Found \(sortedArchives.count) matching archive(s)")

    return sortedArchives
  }

  /// Find the latest archive matching the given filters
  /// - Parameters:
  ///   - appNameFilter: Optional case-insensitive partial match for app name
  ///   - bundleIDFilter: Optional case-insensitive partial match for bundle ID
  /// - Returns: The most recent matching archive
  /// - Throws: ArchiveError if no matching archives found
  func findLatestArchive(
    appNameFilter: String? = nil,
    bundleIDFilter: String? = nil
  ) async throws -> XcodeArchive {
    let archives = try await findArchives(
      appNameFilter: appNameFilter,
      bundleIDFilter: bundleIDFilter
    )

    guard let latest = archives.first else {
      throw ArchiveError.noMatchingArchives(appName: appNameFilter, bundleID: bundleIDFilter)
    }

    logger.info(
      "Found latest archive",
      metadata: [
        "name": .string(latest.name),
        "version": .string(latest.version),
        "buildNumber": .string(latest.buildNumber),
        "date": .string(FormatHelpers.formatDate(latest.creationDate)),
      ])

    return latest
  }

  // MARK: - Private Methods

  /// Find all .xcarchive directories in the archives directory
  private func findAllArchivePaths() throws -> [URL] {
    let fileManager = FileManager.default
    var archivePaths: [URL] = []

    // Get all date-based subdirectories (e.g., 2025-05-31)
    let dateDirs = try fileManager.contentsOfDirectory(
      at: archivesDirectory,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    )

    // Search for .xcarchive directories in each date directory
    for dateDir in dateDirs {
      var isDirectory: ObjCBool = false
      guard fileManager.fileExists(atPath: dateDir.path, isDirectory: &isDirectory),
        isDirectory.boolValue
      else {
        continue
      }

      let archives = try fileManager.contentsOfDirectory(
        at: dateDir,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
      ).filter { $0.pathExtension == "xcarchive" }

      archivePaths.append(contentsOf: archives)
    }

    return archivePaths
  }

  /// Parse an archive's Info.plist to extract metadata
  private func parseArchive(at url: URL) throws -> XcodeArchive {
    let infoPlistURL = url.appendingPathComponent("Info.plist")

    // Verify Info.plist exists
    guard FileManager.default.fileExists(atPath: infoPlistURL.path) else {
      throw ArchiveError.infoPlistNotFound(url)
    }

    // Read and parse Info.plist
    guard let plistData = FileManager.default.contents(atPath: infoPlistURL.path) else {
      throw ArchiveError.infoPlistInvalid(url, "Failed to read file")
    }

    let plist: [String: Any]
    do {
      guard
        let parsed = try PropertyListSerialization.propertyList(
          from: plistData,
          options: [],
          format: nil
        ) as? [String: Any]
      else {
        throw ArchiveError.infoPlistInvalid(url, "Not a dictionary")
      }
      plist = parsed
    } catch {
      throw ArchiveError.infoPlistInvalid(url, "Serialization failed: \(error)")
    }

    // Extract required fields
    guard let name = plist["Name"] as? String else {
      throw ArchiveError.infoPlistInvalid(url, "Missing 'Name' key")
    }

    guard let creationDate = plist["CreationDate"] as? Date else {
      throw ArchiveError.infoPlistInvalid(url, "Missing 'CreationDate' key")
    }

    guard let appProps = plist["ApplicationProperties"] as? [String: Any] else {
      throw ArchiveError.infoPlistInvalid(url, "Missing 'ApplicationProperties' dictionary")
    }

    guard let bundleID = appProps["CFBundleIdentifier"] as? String else {
      throw ArchiveError.infoPlistInvalid(
        url, "Missing 'CFBundleIdentifier' in ApplicationProperties")
    }

    guard let version = appProps["CFBundleShortVersionString"] as? String else {
      throw ArchiveError.infoPlistInvalid(
        url, "Missing 'CFBundleShortVersionString' in ApplicationProperties")
    }

    guard let buildNumber = appProps["CFBundleVersion"] as? String else {
      throw ArchiveError.infoPlistInvalid(url, "Missing 'CFBundleVersion' in ApplicationProperties")
    }

    // Construct dSYMs path
    let dsymsPath = url.appendingPathComponent("dSYMs")

    return XcodeArchive(
      id: url.path,
      path: url,
      name: name,
      bundleID: bundleID,
      version: version,
      buildNumber: buildNumber,
      creationDate: creationDate,
      dsymsPath: dsymsPath
    )
  }
}
