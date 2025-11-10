---
description: Guide user through setting up App Store Connect API credentials
---

# Setup App Store Connect Credentials

Interactive guide to help users configure App Store Connect API credentials for the MCP server.

## Workflow

1. Explain what credentials are needed
2. Provide step-by-step instructions to obtain credentials
3. Guide through credential storage options
4. Test the credentials
5. Confirm successful setup

## Credentials Required

Explain that users need:
- **Key ID**: App Store Connect API Key identifier
- **Issuer ID**: App Store Connect Issuer identifier
- **Private Key**: .p8 file downloaded from App Store Connect

## Step-by-Step Instructions

### 1. Obtain Credentials

Guide the user through:
1. Sign in to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to Users and Access > Keys
3. Click the "+" button to create a new API key
4. Select appropriate permissions (at minimum: "App Manager" or "Developer")
5. Download the private key (.p8 file) - **can only be downloaded once**
6. Note the Key ID (shown in the keys list)
7. Note the Issuer ID (shown at the top of the Keys page)

### 2. Storage Options

Present two options:

**Option A: Environment Variables (Recommended for development)**
```bash
export ASC_KEY_ID="ABC123DEF4"
export ASC_ISSUER_ID="12345678-1234-1234-1234-123456789012"
export ASC_PRIVATE_KEY_PATH="/path/to/AuthKey_ABC123DEF4.p8"
```

**Option B: Claude Code Configuration**
Add to plugin configuration or use `claude add mcp` command.

### 3. Security Best Practices

Warn the user about:
- Never commit .p8 files to version control
- Store .p8 files in a secure location (e.g., `~/.appstoreconnect/`)
- Set proper file permissions: `chmod 600 ~/.appstoreconnect/AuthKey_*.p8`
- Consider using a secrets manager for production use
- The .p8 file can only be downloaded once - back it up securely

### 4. Test Credentials

After setup, test by:
1. Using the `list_apps` tool
2. Confirming at least one app is returned
3. Display success message with app count

## Example Interaction

```
User: "Help me set up App Store Connect credentials"