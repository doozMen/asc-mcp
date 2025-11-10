# Certificate Management Tools Implementation

## Overview
Implemented 4 MCP tools for managing iOS/Mac certificates via App Store Connect API (Issue #2).

## Implementation Details

### Files Created

#### 1. `/Users/stijnwillems/Developer/asc-mcp/Sources/appstoreconnect-mcp/Tools/ListCertificates.swift`
**Tool:** `list_certificates`
- Lists all certificates with optional type filtering
- Displays certificate name, type, expiration date, status, and ID
- Status calculated based on activation state and expiration date
- Formatted table output for easy reading

**Parameters:**
- `certificate_type` (optional): Filter by certificate type (IOS_DEVELOPMENT, IOS_DISTRIBUTION, etc.)

**Output:** Formatted table with columns:
- NAME (30 chars)
- TYPE (25 chars)
- EXPIRES (20 chars)
- STATUS (15 chars): ACTIVE, INACTIVE, or EXPIRED
- ID

#### 2. `/Users/stijnwillems/Developer/asc-mcp/Sources/appstoreconnect-mcp/Tools/CreateCertificate.swift`
**Tool:** `create_certificate`
- Creates new certificate using Certificate Signing Request (CSR)
- Returns certificate details including ID, type, display name, expiration date, serial number, and platform

**Parameters:**
- `certificate_type` (required): Type of certificate to create
- `csr_content` (required): Base64-encoded CSR content

**Output:** Certificate details with reminder to use `download_certificate` tool

#### 3. `/Users/stijnwillems/Developer/asc-mcp/Sources/appstoreconnect-mcp/Tools/RevokeCertificate.swift`
**Tool:** `revoke_certificate`
- Revokes a certificate permanently (cannot be undone)
- Shows certificate details before revoking for confirmation

**Parameters:**
- `certificate_id` (required): Certificate ID to revoke

**Output:** Confirmation with certificate details and warning about permanent revocation

#### 4. `/Users/stijnwillems/Developer/asc-mcp/Sources/appstoreconnect-mcp/Tools/DownloadCertificate.swift`
**Tool:** `download_certificate`
- Downloads certificate as .cer file
- Decodes base64 content and writes to specified path
- Creates output directory if needed

**Parameters:**
- `certificate_id` (required): Certificate ID to download
- `output_path` (required): Local file path for .cer file

**Output:** Download confirmation with file path, size, and installation instructions

### Modified Files

#### `/Users/stijnwillems/Developer/asc-mcp/Sources/appstoreconnect-mcp/AppStoreConnectClient.swift`

**Error Types Added:**
- `certificateNotFound(String)`: Certificate not found error
- `certificateCreationFailed(String)`: Certificate creation error
- `certificateRevokeFailed(String)`: Certificate revocation error
- `invalidCertificateType(String)`: Invalid certificate type error

**Methods Added to AppStoreConnectClientWrapper:**

1. `listCertificates(certificateTypeFilter:)` - List certificates with optional filtering
2. `getCertificate(id:)` - Get certificate by ID
3. `createCertificate(csrContent:certificateType:)` - Create new certificate
4. `revokeCertificate(id:)` - Revoke certificate
5. `downloadCertificate(id:outputPath:)` - Download certificate as .cer file

**Access Level Changes:**
- Changed `client` and `logger` from `private` to `internal` to support extensions

#### `/Users/stijnwillems/Developer/asc-mcp/Sources/appstoreconnect-mcp/MCPServer.swift`

**Tools Registered:**
- Added 4 certificate tools to `getTools()` with complete JSON schemas
- Added handler cases for all 4 tools in `handleToolCall()`

**Tool Schemas Include:**
- All 18 certificate types as enum values
- Required/optional parameters with descriptions
- Type safety for inputs

#### `/Users/stijnwillems/Developer/asc-mcp/Sources/appstoreconnect-mcp/AppStoreConnectClient+Profiles.swift`
**Bug Fix:**
- Fixed Swift 6.0 error in `createProfile()` method
- Added `try` keyword to throwing closure on line 67

## Certificate Types Supported

All 18 App Store Connect certificate types:
- IOS_DEVELOPMENT
- IOS_DISTRIBUTION
- MAC_APP_DEVELOPMENT
- MAC_APP_DISTRIBUTION
- MAC_INSTALLER_DISTRIBUTION
- DEVELOPER_ID_APPLICATION
- DEVELOPER_ID_APPLICATION_G2
- DEVELOPER_ID_KEXT
- DEVELOPER_ID_KEXT_G2
- DEVELOPMENT
- DISTRIBUTION
- PASS_TYPE_ID
- PASS_TYPE_ID_WITH_NFC
- APPLE_PAY
- APPLE_PAY_MERCHANT_IDENTITY
- APPLE_PAY_PSP_IDENTITY
- APPLE_PAY_RSA
- IDENTITY_ACCESS

## Implementation Patterns

### Error Handling
- Comprehensive try-catch blocks
- Specific error types for certificate operations
- Detailed error messages with context
- Structured logging at debug, info, and error levels

### Data Flow
1. Tool handler extracts and validates parameters
2. Calls AppStoreConnectClientWrapper method
3. Client sends request to App Store Connect API
4. Response processed and formatted
5. Returns CallTool.Result with text content

### Logging
- Debug: Input parameters and API responses
- Info: Successful operations
- Error: Failed operations with details

### Code Quality
- Swift 6.0 compatible
- Actor-isolated for thread safety
- Sendable conformance
- Follows existing project patterns
- Formatted with `swift format`

## Testing

Build completed successfully:
```bash
swift build
# Build complete! (4.38s)
```

All tools compile without errors and follow the established pattern from existing tools like `list_apps`, `download_dsyms`, etc.

## Usage Examples

### List all certificates
```json
{
  "tool": "list_certificates"
}
```

### List iOS distribution certificates only
```json
{
  "tool": "list_certificates",
  "arguments": {
    "certificate_type": "IOS_DISTRIBUTION"
  }
}
```

### Create iOS development certificate
```json
{
  "tool": "create_certificate",
  "arguments": {
    "certificate_type": "IOS_DEVELOPMENT",
    "csr_content": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS..."
  }
}
```

### Download certificate
```json
{
  "tool": "download_certificate",
  "arguments": {
    "certificate_id": "ABC123DEF456",
    "output_path": "/Users/developer/certificates/ios_distribution.cer"
  }
}
```

### Revoke certificate
```json
{
  "tool": "revoke_certificate",
  "arguments": {
    "certificate_id": "ABC123DEF456"
  }
}
```

## API Reference

Uses `asc-swift` library (v1.4.1) Resources.v1.certificates endpoints:
- GET /v1/certificates - List certificates
- POST /v1/certificates - Create certificate
- DELETE /v1/certificates/{id} - Revoke certificate
- GET /v1/certificates/{id} - Get certificate details

## Notes

- Certificate content is base64-encoded in API responses
- Download creates parent directories automatically
- Revocation is permanent and cannot be undone
- Status determined from `isActivated` flag and `expirationDate`
- All operations require valid App Store Connect API credentials
