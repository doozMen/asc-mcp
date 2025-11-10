# Bundle ID Management - Usage Examples

## Overview

This document provides practical examples of using the Bundle ID management tools.

## Prerequisites

Ensure App Store Connect credentials are configured:
```bash
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="path/to/private_key.p8"
```

## Tool Examples

### 1. List Bundle IDs

#### List all bundle IDs
```bash
# Show all bundle IDs in your account
appstoreconnect-mcp <<< '{"method":"tools/call","params":{"name":"list_bundle_ids","arguments":{}}}'
```

**Output:**
```
Found 15 bundle ID(s)

Identifier                               Name                           Platform     ID
----------------------------------------------------------------------------------------------------
com.example.myapp                        My App                         IOS          ABC123XYZ
com.example.anotherapp                   Another App                    IOS          DEF456UVW
com.example.macapp                       Mac App                        MAC_OS       GHI789RST
```

#### Filter by platform
```bash
# List only iOS bundle IDs
appstoreconnect-mcp <<< '{
  "method":"tools/call",
  "params":{
    "name":"list_bundle_ids",
    "arguments":{"platform":"IOS"}
  }
}'
```

#### Filter by identifier pattern
```bash
# Find bundle IDs matching "example"
appstoreconnect-mcp <<< '{
  "method":"tools/call",
  "params":{
    "name":"list_bundle_ids",
    "arguments":{"identifier_filter":"com.example"}
  }
}'
```

### 2. Register Bundle ID

#### Register new iOS app bundle ID
```bash
appstoreconnect-mcp <<< '{
  "method":"tools/call",
  "params":{
    "name":"register_bundle_id",
    "arguments":{
      "identifier":"com.example.newapp",
      "name":"My New App",
      "platform":"IOS"
    }
  }
}'
```

**Output:**
```
Successfully Registered Bundle ID
================================

ID: ABC123XYZ
Identifier: com.example.newapp
Name: My New App
Platform: IOS
Seed ID: ABCDEF1234
```

#### Register macOS app bundle ID
```bash
appstoreconnect-mcp <<< '{
  "method":"tools/call",
  "params":{
    "name":"register_bundle_id",
    "arguments":{
      "identifier":"com.example.macapp",
      "name":"My Mac App",
      "platform":"MAC_OS"
    }
  }
}'
```

### 3. Get Bundle ID Details

#### Get by identifier
```bash
appstoreconnect-mcp <<< '{
  "method":"tools/call",
  "params":{
    "name":"get_bundle_id",
    "arguments":{"bundle_id":"com.example.myapp"}
  }
}'
```

**Output:**
```
Bundle ID Details
=================

ID: ABC123XYZ
Identifier: com.example.myapp
Name: My App
Platform: IOS
Seed ID: ABCDEF1234

Capabilities (5):
-------------
  - PUSH_NOTIFICATIONS
  - ICLOUD
  - APP_GROUPS
  - IN_APP_PURCHASE
  - GAME_CENTER
```

#### Get by App Store Connect ID
```bash
appstoreconnect-mcp <<< '{
  "method":"tools/call",
  "params":{
    "name":"get_bundle_id",
    "arguments":{"bundle_id":"ABC123XYZ"}
  }
}'
```

### 4. Update Bundle ID Capabilities

#### Enable push notifications and iCloud
```bash
appstoreconnect-mcp <<< '{
  "method":"tools/call",
  "params":{
    "name":"update_bundle_id_capabilities",
    "arguments":{
      "bundle_id":"com.example.myapp",
      "capabilities":["PUSH_NOTIFICATIONS","ICLOUD"]
    }
  }
}'
```

**Output:**
```
Bundle ID Capabilities Updated
==============================

Bundle ID: com.example.myapp
Name: My App

Newly Enabled Capabilities (2):
  ✓ PUSH_NOTIFICATIONS
  ✓ ICLOUD

Total Capabilities Enabled: 2
  • PUSH_NOTIFICATIONS
  • ICLOUD
```

#### Enable multiple capabilities at once
```bash
appstoreconnect-mcp <<< '{
  "method":"tools/call",
  "params":{
    "name":"update_bundle_id_capabilities",
    "arguments":{
      "bundle_id":"com.example.myapp",
      "capabilities":[
        "PUSH_NOTIFICATIONS",
        "ICLOUD",
        "APP_GROUPS",
        "HEALTHKIT",
        "HOMEKIT"
      ]
    }
  }
}'
```

**Output:**
```
Bundle ID Capabilities Updated
==============================

Bundle ID: com.example.myapp
Name: My App

Newly Enabled Capabilities (3):
  ✓ APP_GROUPS
  ✓ HEALTHKIT
  ✓ HOMEKIT

Already Enabled (skipped 2):
  - PUSH_NOTIFICATIONS
  - ICLOUD

Total Capabilities Enabled: 5
  • PUSH_NOTIFICATIONS
  • ICLOUD
  • APP_GROUPS
  • HEALTHKIT
  • HOMEKIT
```

## Common Workflows

### Complete App Setup Workflow

```bash
# 1. Register bundle ID
appstoreconnect-mcp <<< '{
  "method":"tools/call",
  "params":{
    "name":"register_bundle_id",
    "arguments":{
      "identifier":"com.example.healthapp",
      "name":"Health Tracker",
      "platform":"IOS"
    }
  }
}'

# 2. Enable required capabilities
appstoreconnect-mcp <<< '{
  "method":"tools/call",
  "params":{
    "name":"update_bundle_id_capabilities",
    "arguments":{
      "bundle_id":"com.example.healthapp",
      "capabilities":[
        "PUSH_NOTIFICATIONS",
        "HEALTHKIT",
        "ICLOUD"
      ]
    }
  }
}'

# 3. Verify configuration
appstoreconnect-mcp <<< '{
  "method":"tools/call",
  "params":{
    "name":"get_bundle_id",
    "arguments":{"bundle_id":"com.example.healthapp"}
  }
}'
```

### Audit Existing Bundle IDs

```bash
# 1. List all iOS bundle IDs
appstoreconnect-mcp <<< '{
  "method":"tools/call",
  "params":{
    "name":"list_bundle_ids",
    "arguments":{"platform":"IOS"}
  }
}'

# 2. Get details for each bundle ID
# (Use identifiers from previous step)
for bundle_id in com.example.app1 com.example.app2; do
  appstoreconnect-mcp <<< "{
    \"method\":\"tools/call\",
    \"params\":{
      \"name\":\"get_bundle_id\",
      \"arguments\":{\"bundle_id\":\"$bundle_id\"}
    }
  }"
done
```

## Available Capability Types

Full list of supported capabilities:

- `ICLOUD` - iCloud storage
- `IN_APP_PURCHASE` - In-App Purchases
- `GAME_CENTER` - Game Center integration
- `PUSH_NOTIFICATIONS` - Push notifications
- `WALLET` - Apple Wallet/Passbook
- `INTER_APP_AUDIO` - Inter-App Audio
- `MAPS` - Maps integration
- `ASSOCIATED_DOMAINS` - Associated Domains
- `PERSONAL_VPN` - Personal VPN
- `APP_GROUPS` - App Groups
- `HEALTHKIT` - HealthKit
- `HOMEKIT` - HomeKit
- `WIRELESS_ACCESSORY_CONFIGURATION` - Wireless Accessory Configuration
- `APPLE_PAY` - Apple Pay
- `DATA_PROTECTION` - Data Protection
- `SIRIKIT` - SiriKit
- `NETWORK_EXTENSIONS` - Network Extensions
- `MULTIPATH` - Multipath networking
- `HOT_SPOT` - Hotspot Configuration
- `NFC_TAG_READING` - NFC Tag Reading
- `CLASSKIT` - ClassKit
- `AUTOFILL_CREDENTIAL_PROVIDER` - AutoFill Credential Provider
- `ACCESS_WIFI_INFORMATION` - Access WiFi Information
- `NETWORK_CUSTOM_PROTOCOL` - Network Custom Protocol
- `COREMEDIA_HLS_LOW_LATENCY` - CoreMedia HLS Low Latency
- `SYSTEM_EXTENSION_INSTALL` - System Extension Install
- `USER_MANAGEMENT` - User Management
- `APPLE_ID_AUTH` - Sign in with Apple

## Error Examples

### Invalid Bundle ID Format
```bash
# Missing domain component
appstoreconnect-mcp <<< '{
  "method":"tools/call",
  "params":{
    "name":"register_bundle_id",
    "arguments":{
      "identifier":"myapp",
      "name":"My App",
      "platform":"IOS"
    }
  }
}'
```

**Error:**
```
Invalid bundle ID: Bundle ID must be in reverse domain notation (e.g., com.example.app)
```

### Invalid Platform
```bash
appstoreconnect-mcp <<< '{
  "method":"tools/call",
  "params":{
    "name":"register_bundle_id",
    "arguments":{
      "identifier":"com.example.app",
      "name":"My App",
      "platform":"ANDROID"
    }
  }
}'
```

**Error:**
```
Invalid platform: ANDROID. Valid values: IOS, MAC_OS, UNIVERSAL
```

### Invalid Capability
```bash
appstoreconnect-mcp <<< '{
  "method":"tools/call",
  "params":{
    "name":"update_bundle_id_capabilities",
    "arguments":{
      "bundle_id":"com.example.app",
      "capabilities":["INVALID_CAPABILITY"]
    }
  }
}'
```

**Error:**
```
Invalid capability: INVALID_CAPABILITY. See documentation for valid capability types.
```

## Tips

1. **Idempotent Operations**: `update_bundle_id_capabilities` automatically skips already-enabled capabilities, making it safe to run multiple times.

2. **Flexible ID Resolution**: Both `get_bundle_id` and `update_bundle_id_capabilities` accept either bundle identifiers (com.example.app) or App Store Connect IDs.

3. **Batch Operations**: Use shell scripts to perform operations on multiple bundle IDs.

4. **Validation**: Bundle ID format is validated before API calls, providing immediate feedback for invalid formats.

5. **Platform Compatibility**: Remember that some capabilities are platform-specific (e.g., HOMEKIT is iOS-only).
