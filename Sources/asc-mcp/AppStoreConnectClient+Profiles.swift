import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging

extension AppStoreConnectClientWrapper {
  /// List all provisioning profiles with optional filters
  func listProfiles(
    profileType: String? = nil,
    bundleIDFilter: String? = nil
  ) async throws -> ProfilesResponse {
    do {
      // Map profile type string to enum
      let profileTypeFilter: Resources.V1.Profiles.FilterProfileType? = {
        guard let typeString = profileType else { return nil }
        switch typeString.uppercased() {
        case "IOS_APP_DEVELOPMENT":
          return .iOSAppDevelopment
        case "IOS_APP_STORE":
          return .iOSAppStore
        case "IOS_APP_ADHOC":
          return .iOSAppAdhoc
        case "IOS_APP_INHOUSE":
          return .iOSAppInhouse
        case "MAC_APP_DEVELOPMENT":
          return .macAppDevelopment
        case "MAC_APP_STORE":
          return .macAppStore
        case "MAC_APP_DIRECT":
          return .macAppDirect
        case "TVOS_APP_DEVELOPMENT":
          return .tvOSAppDevelopment
        case "TVOS_APP_STORE":
          return .tvOSAppStore
        case "TVOS_APP_ADHOC":
          return .tvOSAppAdhoc
        default:
          return nil
        }
      }()

      let response = try await client.send(
        Resources.v1.profiles.get(
          filterProfileType: profileTypeFilter.map { [$0] },
          include: [.bundleID]
        )
      )

      logger.debug("Retrieved \(response.data.count) profiles")
      return response
    } catch {
      logger.error("Failed to list profiles", metadata: ["error": "\(error)"])
      throw error
    }
  }

  /// Create a new provisioning profile
  func createProfile(
    name: String,
    profileType: String,
    bundleID: String,
    certificateIDs: [String],
    deviceIDs: [String]?
  ) async throws -> Profile {
    do {
      // Map profile type string to enum
      let profileTypeEnum: ProfileCreateRequest.Data.Attributes.ProfileType = {
        switch profileType.uppercased() {
        case "IOS_APP_DEVELOPMENT":
          return .iOSAppDevelopment
        case "IOS_APP_STORE":
          return .iOSAppStore
        case "IOS_APP_ADHOC":
          return .iOSAppAdhoc
        case "IOS_APP_INHOUSE":
          return .iOSAppInhouse
        case "MAC_APP_DEVELOPMENT":
          return .macAppDevelopment
        case "MAC_APP_STORE":
          return .macAppStore
        case "MAC_APP_DIRECT":
          return .macAppDirect
        case "TVOS_APP_DEVELOPMENT":
          return .tvOSAppDevelopment
        case "TVOS_APP_STORE":
          return .tvOSAppStore
        case "TVOS_APP_ADHOC":
          return .tvOSAppAdhoc
        default:
          fatalError("Invalid profile type: \(profileType)")
        }
      }()

      // Build request
      let attributes = ProfileCreateRequest.Data.Attributes(
        name: name,
        profileType: profileTypeEnum
      )

      let bundleIDData = ProfileCreateRequest.Data.Relationships.BundleID.Data(id: bundleID)
      let bundleIDRelation = ProfileCreateRequest.Data.Relationships.BundleID(data: bundleIDData)

      let certificatesData = certificateIDs.map {
        ProfileCreateRequest.Data.Relationships.Certificates.Datum(id: $0)
      }
      let certificatesRelation = ProfileCreateRequest.Data.Relationships.Certificates(
        data: certificatesData)

      let devicesRelation: ProfileCreateRequest.Data.Relationships.Devices? = deviceIDs.map {
        ids in
        ProfileCreateRequest.Data.Relationships.Devices(
          data: ids.map { ProfileCreateRequest.Data.Relationships.Devices.Datum(id: $0) }
        )
      }

      let relationships = ProfileCreateRequest.Data.Relationships(
        bundleID: bundleIDRelation,
        devices: devicesRelation,
        certificates: certificatesRelation
      )

      let requestData = ProfileCreateRequest.Data(
        attributes: attributes,
        relationships: relationships
      )

      let request = ProfileCreateRequest(data: requestData)

      let response = try await client.send(Resources.v1.profiles.post(request))

      logger.info(
        "Created profile",
        metadata: [
          "id": "\(response.data.id)",
          "name": "\(response.data.attributes?.name ?? "unknown")",
        ])

      return response.data
    } catch {
      logger.error("Failed to create profile", metadata: ["name": "\(name)", "error": "\(error)"])
      throw error
    }
  }

  /// Delete a provisioning profile
  func deleteProfile(id: String) async throws {
    do {
      _ = try await client.send(Resources.v1.profiles.id(id).delete)
      logger.info("Deleted profile", metadata: ["id": "\(id)"])
    } catch {
      logger.error("Failed to delete profile", metadata: ["id": "\(id)", "error": "\(error)"])
      throw error
    }
  }

  /// Download provisioning profile content
  ///
  /// Downloads the .mobileprovision file for a profile and saves it to the specified path.
  ///
  /// - Parameters:
  ///   - profileID: The App Store Connect profile ID
  ///   - outputPath: File path where the .mobileprovision should be saved
  /// - Returns: URL to the saved .mobileprovision file
  /// - Throws: ASCError if the profile is not found or download fails
  func downloadProfile(profileID: String, outputPath: String) async throws -> URL {
    logger.debug(
      "Downloading profile", metadata: ["profileID": "\(profileID)", "outputPath": "\(outputPath)"]
    )

    do {
      // 1. Get profile with content included
      let response = try await client.send(
        Resources.v1.profiles.id(profileID).get(
          fieldsProfiles: [.profileContent, .name, .profileType, .expirationDate]
        )
      )

      let profile = response.data

      // 2. Extract profile content (base64 encoded)
      guard let profileContent = profile.attributes?.profileContent else {
        throw ASCError.downloadFailed(
          "No profile content available for profile \(profileID). The profile may not be active.")
      }

      // 3. Decode base64 content
      guard let profileData = Data(base64Encoded: profileContent) else {
        throw ASCError.downloadFailed("Failed to decode profile content for profile \(profileID)")
      }

      // 4. Create output path
      let outputURL = URL(filePath: outputPath)

      // Ensure parent directory exists
      let parentDirectory = outputURL.deletingLastPathComponent()
      if !FileManager.default.fileExists(atPath: parentDirectory.path) {
        try FileManager.default.createDirectory(
          at: parentDirectory, withIntermediateDirectories: true)
      }

      // 5. Save to file
      try profileData.write(to: outputURL)

      logger.info(
        "Successfully downloaded profile",
        metadata: [
          "profileID": "\(profileID)",
          "name": "\(profile.attributes?.name ?? "unknown")",
          "outputPath": "\(outputURL.path)",
          "size": "\(profileData.count)",
        ])

      return outputURL
    } catch let error as ASCError {
      logger.error(
        "Failed to download profile",
        metadata: ["profileID": "\(profileID)", "error": "\(error.localizedDescription)"])
      throw error
    } catch {
      logger.error(
        "Failed to download profile", metadata: ["profileID": "\(profileID)", "error": "\(error)"])
      throw error
    }
  }
}
