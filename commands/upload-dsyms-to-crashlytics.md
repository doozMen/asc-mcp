---
description: Upload dSYM files to Firebase Crashlytics for crash symbolication
---

# Upload dSYMs to Firebase Crashlytics

Complete workflow for uploading dSYM files to Firebase Crashlytics from various sources.

## Workflow

1. Ask the user for Firebase app ID (format: "1:123456789:ios:abc123def456")
2. Determine the dSYM source:
   - **Option A**: Latest App Store Connect build
   - **Option B**: Specific App Store Connect build ID
   - **Option C**: Local Xcode archive
   - **Option D**: Direct dSYM path

3. Execute the appropriate workflow:
   - For App Store Connect: Use `get_latest_build` then `upload_dsyms_to_firebase`
   - For Xcode archive: Use `find_xcode_archives` then `upload_dsyms_to_firebase`
   - For direct path: Use `upload_dsyms_to_firebase` directly

4. Confirm successful upload with details

## Prerequisites Check

Before executing, verify:
- Firebase CLI is installed (`firebase --version`)
- User has Firebase credentials configured
- GoogleService-Info.plist exists in the project (if applicable)

## Example Interactions

**From latest build:**
```
User: "Upload the latest dSYMs to Firebase Crashlytics"
Assistant: "What's your Firebase app ID?"
User: "1:123456789:ios:abc123def456"
Assistant: "What's your app's bundle ID?"
User: "com.example.myapp"
[Executes workflow]
```

**From local archive:**
```
User: "Upload dSYMs from my latest Xcode archive"
Assistant: "What's your Firebase app ID?"
User: "1:123456789:ios:abc123def456"
[Uses find_xcode_archives with latest_only=true]
[Executes upload]
```

## Output

- Confirm which dSYMs were uploaded
- Display Firebase upload status
- Show build version and number
- Provide verification instructions (check Firebase console)

## Error Handling

- Check Firebase CLI installation
- Verify Firebase app ID format
- Handle authentication errors
- Provide clear error messages for missing prerequisites
