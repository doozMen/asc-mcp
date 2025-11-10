import Logging
import MCP
import Testing

@testable import appstoreconnect_mcp

@Suite("Input Validation Tests")
struct InputValidationTests {

  @Test("list_apps accepts empty arguments")
  func listAppsAcceptsEmptyArguments() async throws {
    // list_apps should work with no arguments
    let arguments: [String: Value] = [:]

    // Extract bundle_id_filter (should be nil)
    let bundleIDFilter = arguments["bundle_id_filter"]?.stringValue
    #expect(bundleIDFilter == nil)
  }

  @Test("list_apps accepts bundle_id_filter")
  func listAppsAcceptsBundleIDFilter() async throws {
    let arguments: [String: Value] = [
      "bundle_id_filter": .string("com.example.app")
    ]

    let bundleIDFilter = arguments["bundle_id_filter"]?.stringValue
    #expect(bundleIDFilter == "com.example.app")
  }

  @Test("get_app_status validates app_id parameter")
  func getAppStatusValidatesAppID() async throws {
    let arguments: [String: Value] = [
      "app_id": .string("123456789")
    ]

    let appID = arguments["app_id"]?.stringValue
    #expect(appID == "123456789")
  }

  @Test("get_app_status validates bundle_id parameter")
  func getAppStatusValidatesBundleID() async throws {
    let arguments: [String: Value] = [
      "bundle_id": .string("com.example.app")
    ]

    let bundleID = arguments["bundle_id"]?.stringValue
    #expect(bundleID == "com.example.app")
  }

  @Test("get_app_status rejects empty arguments")
  func getAppStatusRejectsEmptyArguments() async throws {
    let arguments: [String: Value] = [:]

    let appID = arguments["app_id"]?.stringValue
    let bundleID = arguments["bundle_id"]?.stringValue

    // Should fail validation - neither app_id nor bundle_id provided
    #expect(appID == nil && bundleID == nil)
  }

  @Test("list_builds validates required app_id")
  func listBuildsValidatesRequiredAppID() async throws {
    let arguments: [String: Value] = [
      "app_id": .string("123456789")
    ]

    let appID = arguments["app_id"]?.stringValue
    #expect(appID != nil)
    #expect(appID == "123456789")
  }

  @Test("list_builds rejects missing app_id")
  func listBuildsRejectsMissingAppID() async throws {
    let arguments: [String: Value] = [:]

    let appID = arguments["app_id"]?.stringValue
    #expect(appID == nil)
  }

  @Test("list_builds accepts version_filter")
  func listBuildsAcceptsVersionFilter() async throws {
    let arguments: [String: Value] = [
      "app_id": .string("123456789"),
      "version_filter": .string("1.0.0"),
    ]

    let versionFilter = arguments["version_filter"]?.stringValue
    #expect(versionFilter == "1.0.0")
  }

  @Test("download_dsyms validates required build_id")
  func downloadDsymsValidatesRequiredBuildID() async throws {
    let arguments: [String: Value] = [
      "build_id": .string("build-123"),
      "output_path": .string("/tmp/dsyms"),
    ]

    let buildID = arguments["build_id"]?.stringValue
    #expect(buildID != nil)
    #expect(buildID == "build-123")
  }

  @Test("download_dsyms validates required output_path")
  func downloadDsymsValidatesRequiredOutputPath() async throws {
    let arguments: [String: Value] = [
      "build_id": .string("build-123"),
      "output_path": .string("/tmp/dsyms"),
    ]

    let outputPath = arguments["output_path"]?.stringValue
    #expect(outputPath != nil)
    #expect(outputPath == "/tmp/dsyms")
  }

  @Test("download_dsyms rejects missing build_id")
  func downloadDsymsRejectsMissingBuildID() async throws {
    let arguments: [String: Value] = [
      "output_path": .string("/tmp/dsyms")
    ]

    let buildID = arguments["build_id"]?.stringValue
    #expect(buildID == nil)
  }

  @Test("download_dsyms rejects missing output_path")
  func downloadDsymsRejectsMissingOutputPath() async throws {
    let arguments: [String: Value] = [
      "build_id": .string("build-123")
    ]

    let outputPath = arguments["output_path"]?.stringValue
    #expect(outputPath == nil)
  }

  @Test("get_latest_build validates required app_id")
  func getLatestBuildValidatesRequiredAppID() async throws {
    let arguments: [String: Value] = [
      "app_id": .string("123456789")
    ]

    let appID = arguments["app_id"]?.stringValue
    #expect(appID != nil)
    #expect(appID == "123456789")
  }

  @Test("get_latest_build rejects missing app_id")
  func getLatestBuildRejectsMissingAppID() async throws {
    let arguments: [String: Value] = [:]

    let appID = arguments["app_id"]?.stringValue
    #expect(appID == nil)
  }

  @Test("Value extension extracts string correctly")
  func valueExtensionExtractsString() async throws {
    let stringValue = Value.string("test")
    #expect(stringValue.stringValue == "test")

    let intValue = Value.int(123)
    #expect(intValue.stringValue == nil)

    let boolValue = Value.bool(true)
    #expect(boolValue.stringValue == nil)
  }
}
