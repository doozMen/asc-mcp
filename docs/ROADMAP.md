# App Store Connect MCP Server - Roadmap

**Current Version:** v1.0.0
**Released:** 2025-10-24

---

## Current Features (v1.0.0)

### 10 MCP Tools ✅

**App Store Connect (5):**
- list_apps
- get_app_status
- list_builds
- download_dsyms
- get_latest_build

**Firebase Crashlytics (2):**
- upload_dsyms_to_firebase
- find_xcode_archives

**Firebase Projects (3):**
- list_firebase_projects
- get_firebase_project
- list_firebase_apps (iOS/Android/Web support)

**Coverage:** ~15% of App Store Connect API

---

## Roadmap to Complete iOS Setup Automation

### Phase 1: Core Provisioning (v1.1.0) - HIGH PRIORITY

**Goal:** Enable complete iOS app setup from scratch

**Issues:**
- #2: Certificate Management (4 tools)
- #3: Bundle ID Management (4 tools)
- #4: Provisioning Profile Management (4 tools)

**Tools to Add (12):**
1. `list_certificates` - List all certificates
2. `create_certificate` - Create new certificate
3. `revoke_certificate` - Revoke certificate
4. `download_certificate` - Download .cer file
5. `list_bundle_ids` - List bundle IDs
6. `register_bundle_id` - Register new bundle ID
7. `update_bundle_id_capabilities` - Enable capabilities
8. `get_bundle_id` - Get bundle ID details
9. `list_profiles` - List provisioning profiles
10. `create_profile` - Create new profile
11. `delete_profile` - Delete profile
12. `download_profile` - Download .mobileprovision

**API Support:** ✅ Full support in App Store Connect API
**Implementation:** Use asc-swift Resources.v1.{certificates,bundleIds,profiles}
**Estimated Effort:** 2-3 days
**Priority:** CRITICAL for Promo's Bing app setup

**Deliverables:**
- 12 new MCP tools
- Complete workflow: Register bundle ID → Create cert → Create profile → Download
- Tests for all new tools
- Documentation updates

---

### Phase 2: Push Notifications (v1.2.0) - HIGH PRIORITY

**Goal:** Complete APN certificate setup and Firebase integration

**Issues:**
- #5: APN Certificate Management (4 tools)

**Tools to Add (4):**
1. `create_apn_certificate` - Create APN cert (dev/prod)
2. `list_apn_certificates` - List APN certs
3. `download_apn_certificate` - Download .cer file
4. `upload_apn_to_firebase` - Upload to Firebase Cloud Messaging

**API Support:** ✅ App Store Connect API + Firebase CLI
**Implementation:** Combine ASC certificates API + Firebase CLI
**Estimated Effort:** 1-2 days
**Priority:** CRITICAL for push notification setup

**Deliverables:**
- 4 new MCP tools
- End-to-end APN workflow
- Firebase FCM integration
- Tests and documentation

---

### Phase 3: Build Distribution (v1.3.0) - HIGH PRIORITY

**Goal:** Upload builds to App Store Connect for TestFlight/App Store

**Issues:**
- #7: Build Upload (3 tools)

**Tools to Add (3):**
1. `upload_build` - Upload IPA to App Store Connect
2. `validate_build` - Validate before upload
3. `get_upload_status` - Check upload progress

**API Support:** ⚠️ Requires Transporter CLI (no direct API)
**Implementation:** Use swift-subprocess to wrap iTMSTransporter
**Estimated Effort:** 2-3 days
**Priority:** HIGH for CI/CD automation

**Deliverables:**
- 3 new MCP tools
- Transporter CLI integration
- Upload progress reporting
- Complete CI/CD workflow support

---

### Phase 4: macOS Tools (v1.4.0) - MEDIUM PRIORITY

**Goal:** Support macOS app distribution and CLI tool publishing

**Issues:**
- #6: Notarization Tools (4 tools)

**Tools to Add (4):**
1. `notarize_app` - Notarize macOS app/CLI tool
2. `check_notarization_status` - Check status
3. `staple_notarization` - Staple ticket
4. `notarize_cli_tool` - Complete CLI tool workflow

**API Support:** ✅ notarytool (xcrun notarytool)
**Implementation:** Use swift-subprocess to wrap notarytool
**Estimated Effort:** 1-2 days
**Priority:** MEDIUM (important for macOS, not critical for iOS-only)

**Deliverables:**
- 4 new MCP tools
- Complete notarization workflow
- Stapling support
- Self-hosting capability (notarize this MCP server!)

**Special Use Case:**
- Notarize the asc-mcp tool itself for distribution
- Enable Gatekeeper-safe downloads

---

### Phase 5: Device & TestFlight (v1.5.0) - MEDIUM PRIORITY

**Goal:** Device management and TestFlight automation

**Tools to Add (8):**
1. `list_devices` - List registered devices
2. `register_device` - Add device by UDID
3. `update_device` - Rename/modify
4. `enable_device` / `disable_device` - Status management
5. `add_tester` - Add TestFlight beta tester
6. `list_testers` - List beta testers
7. `create_beta_group` - Create tester group
8. `assign_build_to_testers` - Distribute build

**API Support:** ✅ Full support
**Estimated Effort:** 2-3 days
**Priority:** MEDIUM

---

### Phase 6: App Metadata & Submission (v1.6.0) - LOW PRIORITY

**Goal:** Manage App Store listings and submissions

**Tools to Add (10+):**
1. `create_app` - Create new app in App Store Connect
2. `update_app_info` - Update description, keywords, etc.
3. `create_version` - Create new app version
4. `update_version` - Update version metadata
5. `upload_screenshots` - Upload App Store screenshots
6. `submit_for_review` - Submit version for review
7. `get_review_status` - Check review status
8. `respond_to_review` - Reply to reviewer questions
9. `release_version` - Release approved version
10. `update_pricing` - Manage pricing tiers

**API Support:** ✅ Full support
**Estimated Effort:** 4-5 days
**Priority:** LOW (manual process is acceptable)

---

## Tool Count Projection

| Version | Tools | Coverage |
|---------|-------|----------|
| v1.0.0 (Current) | 10 | ~15% |
| v1.1.0 (Phase 1) | 22 | ~35% |
| v1.2.0 (Phase 2) | 26 | ~40% |
| v1.3.0 (Phase 3) | 29 | ~45% |
| v1.4.0 (Phase 4) | 33 | ~50% |
| v1.5.0 (Phase 5) | 41 | ~65% |
| v1.6.0 (Phase 6) | 51+ | ~80% |

---

## Implementation Strategy

### Parallel Development

**Phase 1 + 2 + 3 Can Run in Parallel:**
- Certificate/Bundle/Profile tools (Phase 1)
- APN tools (Phase 2)
- Build upload (Phase 3)

**Estimated Time:** 5-7 days for all 3 phases

### Agent Collaboration

Use specialized agents:
- @swift-developer (implementation)
- @swift-mcp-server-writer (MCP integration)
- @code-reviewer (quality checks)
- @testing-specialist (test coverage)

---

## Promo's Bing App Requirements

**Immediate Needs:**
1. ✅ Download dSYMs (DONE)
2. ✅ Upload to Firebase Crashlytics (DONE)
3. ❌ Create APN certificate (Phase 2)
4. ❌ Upload APN to Firebase (Phase 2)
5. ❌ Create provisioning profiles (Phase 1)
6. ❌ Upload new builds (Phase 3)

**Recommended Implementation Order:**
1. **Phase 2** (APN) - Unblock push notifications
2. **Phase 1** (Provisioning) - Complete setup automation
3. **Phase 3** (Upload) - CI/CD automation

---

## Beyond iOS

### Android Support (Future)

**Current:** Firebase project tools support Android ✅

**Potential Additions:**
- Google Play Console integration
- Android build upload
- Android app metadata management
- Play Store listing automation

**Effort:** 3-5 days (new API integration)

---

## Success Metrics

**v1.0.0:**
- ✅ 10 tools
- ✅ 41 tests passing
- ✅ Production ready
- ✅ MCP connected

**v1.1.0 Target:**
- 22 tools
- 80+ tests
- Complete provisioning automation
- No manual certificate/profile creation

**v2.0.0 Vision:**
- 50+ tools
- 200+ tests
- Complete iOS/macOS automation
- Android Play Store integration
- Full CI/CD support

---

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for development guidelines.

To request a feature, open an issue with:
- Use case description
- API endpoint reference
- Priority justification

---

**Last Updated:** 2025-10-24
**Next Review:** After Phase 1 completion
