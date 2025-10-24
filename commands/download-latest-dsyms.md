---
description: Download dSYM files from the latest App Store Connect build
---

# Download Latest dSYMs

Automate the workflow of finding and downloading dSYM files from the latest build in App Store Connect.

## Workflow

1. Ask the user for the app bundle ID (e.g., "com.example.myapp")
2. Use `get_app_status` tool to get the app ID
3. Use `get_latest_build` tool to get the latest build ID
4. Use `download_dsyms` tool to download and extract dSYM files
5. Report the download location to the user

## Example Usage

User: "Download the latest dSYMs for my app"
Assistant: "What's your app's bundle ID?"
User: "com.example.myapp"
Assistant: [executes workflow and reports location]

## Output

- Confirm successful download
- Show the path to extracted .dSYM files
- Display build version and build number
- Provide next steps (e.g., upload to Firebase Crashlytics)

## Error Handling

- Verify app exists in App Store Connect
- Check if build has dSYMs available
- Handle download and extraction failures gracefully
- Suggest solutions if dSYMs are missing
