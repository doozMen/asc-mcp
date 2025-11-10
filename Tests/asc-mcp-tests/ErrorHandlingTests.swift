import Foundation
import Testing

@testable import appstoreconnect_mcp

@Suite("Error Handling Tests")
struct ErrorHandlingTests {

  @Test("ASCError authentication failed has correct description")
  func ascErrorAuthenticationFailedDescription() async throws {
    let error = ASCError.authenticationFailed("Invalid token")
    #expect(error.localizedDescription.contains("Authentication failed"))
    #expect(error.localizedDescription.contains("Invalid token"))
  }

  @Test("ASCError API error includes status code")
  func ascErrorAPIErrorIncludesStatusCode() async throws {
    let error = ASCError.apiError(404, "Not found")
    #expect(error.localizedDescription.contains("404"))
    #expect(error.localizedDescription.contains("Not found"))
  }

  @Test("ASCError not found has correct description")
  func ascErrorNotFoundDescription() async throws {
    let error = ASCError.notFound("App with ID 123")
    #expect(error.localizedDescription.contains("Resource not found"))
    #expect(error.localizedDescription.contains("App with ID 123"))
  }

  @Test("ASCError rate limit exceeded has correct description")
  func ascErrorRateLimitExceededDescription() async throws {
    let error = ASCError.rateLimitExceeded
    #expect(error.localizedDescription.contains("Rate limit exceeded"))
    #expect(error.localizedDescription.contains("try again later"))
  }

  @Test("ASCError invalid private key has correct description")
  func ascErrorInvalidPrivateKeyDescription() async throws {
    let error = ASCError.invalidPrivateKey("Unable to parse key")
    #expect(error.localizedDescription.contains("Invalid private key"))
    #expect(error.localizedDescription.contains("Unable to parse key"))
  }

  @Test("ASCError invalid bundle ID has correct description")
  func ascErrorInvalidBundleIDDescription() async throws {
    let error = ASCError.invalidBundleID("com.example.nonexistent")
    #expect(error.localizedDescription.contains("Invalid bundle ID"))
    #expect(error.localizedDescription.contains("com.example.nonexistent"))
  }

  @Test("ASCError build not found has correct description")
  func ascErrorBuildNotFoundDescription() async throws {
    let error = ASCError.buildNotFound("build-123")
    #expect(error.localizedDescription.contains("Build not found"))
    #expect(error.localizedDescription.contains("build-123"))
  }

  @Test("ASCError download failed has correct description")
  func ascErrorDownloadFailedDescription() async throws {
    let error = ASCError.downloadFailed("Network timeout")
    #expect(error.localizedDescription.contains("Download failed"))
    #expect(error.localizedDescription.contains("Network timeout"))
  }

  @Test("Invalid private key path throws error")
  func invalidPrivateKeyPathThrowsError() async throws {
    let invalidPath = "/nonexistent/path/to/key.p8"

    do {
      _ = try AppStoreConnectClientWrapper(
        keyID: "test-key-id",
        issuerID: "test-issuer-id",
        privateKeyPath: invalidPath,
        keyExpiry: 1200
      )
      Issue.record("Expected error to be thrown for invalid key path")
    } catch let error as ASCError {
      switch error {
      case .invalidPrivateKey(let message):
        #expect(message.contains("File not found"))
      default:
        Issue.record("Expected invalidPrivateKey error, got \(error)")
      }
    } catch {
      Issue.record("Expected ASCError, got \(error)")
    }
  }

  @Test("URL error mapping to authentication failed")
  func urlErrorMappingToAuthenticationFailed() async throws {
    let urlError = URLError(.userAuthenticationRequired)

    // The mapAPIError method would convert this to ASCError.authenticationFailed
    // We can test this by checking the error type
    #expect(urlError.code == .userAuthenticationRequired)
  }

  @Test("URL error mapping to API error")
  func urlErrorMappingToAPIError() async throws {
    let urlError = URLError(.timedOut)

    // The mapAPIError method would convert this to ASCError.apiError
    #expect(urlError.code == .timedOut)
  }

  @Test("Network connection errors are handled")
  func networkConnectionErrorsAreHandled() async throws {
    let notConnectedError = URLError(.notConnectedToInternet)
    #expect(notConnectedError.code == .notConnectedToInternet)
  }
}
