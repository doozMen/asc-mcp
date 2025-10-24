# Marketplace Submission Guide

Complete guide for submitting the App Store Connect MCP Plugin to various marketplaces.

## Pre-Submission Checklist

### 1. Validate Plugin Structure

```bash
./validate-plugin.sh
```

Ensure all checks pass (warnings about assets are expected until created).

### 2. Create Visual Assets

#### Icon (Required)
- **File:** `assets/icon.png`
- **Size:** 1024x1024px (PNG with transparency)
- **Design:** iOS/Swift themed with App Store Connect branding
- **See:** `assets/README.md` for detailed guidelines

#### Screenshots (3-5 Required)
- **Files:** `assets/screenshot-1.png` through `assets/screenshot-5.png`
- **Size:** 1280x800px or larger
- **Content:** Show plugin features in action
- **Captions:** Provide clear descriptions for each

**Screenshot Topics:**
1. Download latest dSYMs workflow
2. Upload to Firebase Crashlytics
3. Build status checking
4. Credential setup guide
5. Xcode archive discovery

### 3. Commit Assets to Repository

```bash
# Add assets
git add assets/icon.png assets/screenshot-*.png

# Commit
git commit -m "feat(assets): add plugin icon and screenshots for marketplace"

# Push
git push origin main
```

### 4. Update Manifest URLs

After pushing to GitHub, update these files with GitHub raw URLs:

**File: `.claude-plugin/plugin.json`**
```json
{
  "icon": "https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/icon.png"
}
```

**File: `.claude-plugin/submission-metadata.json`**
```json
{
  "icon": "https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/icon.png",
  "screenshots": [
    {
      "url": "https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/screenshot-1.png",
      "caption": "Download latest dSYMs with single command"
    }
    // ... add all screenshots
  ]
}
```

Commit these changes:
```bash
git add .claude-plugin/plugin.json .claude-plugin/submission-metadata.json
git commit -m "feat(assets): update manifest URLs with GitHub assets"
git push origin main
```

### 5. Create GitHub Release

```bash
# Tag version
git tag -a v1.0.0 -m "Release v1.0.0 - Initial Claude Code plugin release"

# Push tag
git push origin v1.0.0
```

Create release on GitHub:
1. Go to https://github.com/doozMen/asc-mcp/releases/new
2. Select tag: `v1.0.0`
3. Title: `v1.0.0 - Initial Release`
4. Description: Copy from CHANGELOG.md
5. Attach assets (optional)
6. Publish release

### 6. Test Self-Hosted Installation

Before submitting to official marketplace, test thoroughly:

```bash
# Add marketplace
/plugin marketplace add github.com/doozMen/asc-mcp

# Install plugin
/plugin install appstoreconnect-mcp@doozMen

# Navigate and build
cd ~/.claude/plugins/appstoreconnect-mcp
./install.sh

# Test features
```

**Test Checklist:**
- [ ] Plugin installs successfully
- [ ] MCP server builds and installs
- [ ] All 4 slash commands work
- [ ] Agent invokes correctly
- [ ] All 7 MCP tools function
- [ ] Credential setup guide works
- [ ] Documentation is accessible
- [ ] No errors in logs

## Distribution Channels

### Option 1: GitHub Self-Hosted Marketplace (Immediate)

**Status:** ✅ Ready after assets are added

**Steps:**
1. Complete pre-submission checklist
2. Push to GitHub with assets
3. Share installation instructions:
   ```bash
   /plugin marketplace add github.com/doozMen/asc-mcp
   /plugin install appstoreconnect-mcp@doozMen
   ```

**Users can install immediately!**

**Best for:**
- Immediate availability
- Team/corporate distribution
- Beta testing
- No approval needed

### Option 2: Official Claude Code Marketplace

**Status:** ⏳ Requires submission and review

**Submission Process:**

1. **Visit Submission Portal:**
   https://claudecodecommands.directory/submit

2. **Provide Required Information:**
   - Repository URL: `https://github.com/doozMen/asc-mcp`
   - Contact email: `stijn@dooz.io`
   - Plugin category: `development-tools`
   - Short description (from submission-metadata.json)

3. **Submit Manifests:**
   - Link to `plugin.json`:
     `https://raw.githubusercontent.com/doozMen/asc-mcp/main/.claude-plugin/plugin.json`
   - Link to `submission-metadata.json`:
     `https://raw.githubusercontent.com/doozMen/asc-mcp/main/.claude-plugin/submission-metadata.json`

4. **Wait for Review:**
   - Expected time: 1-7 days
   - Reviewers check:
     - Valid manifests
     - Working installation
     - Quality assets
     - Complete documentation
     - No malicious code

5. **Respond to Feedback:**
   - Address any review comments
   - Update repository if needed
   - Resubmit if required

6. **Approval and Listing:**
   - Plugin appears in official marketplace
   - Users can install via:
     ```bash
     /plugin install appstoreconnect-mcp
     ```

**Best for:**
- Maximum discoverability
- Official verification badge
- Centralized listing
- Community trust

### Option 3: Community Marketplaces

**Status:** 🔄 Optional additional distribution

#### A. jeremylongshore/claude-code-plugins (226+ plugins)

**Steps:**
1. Fork: https://github.com/jeremylongshore/claude-code-plugins
2. Add entry to catalog JSON
3. Submit pull request with:
   - Plugin name
   - Description
   - GitHub URL
   - Installation instructions
4. Wait for maintainer approval

#### B. ananddtyagi/claude-code-marketplace

**Steps:**
1. Fork: https://github.com/ananddtyagi/claude-code-marketplace
2. Add plugin entry
3. Submit pull request
4. Wait for approval

**Best for:**
- Additional discovery channels
- Community engagement
- Social proof
- Multiple distribution points

## Submission Timeline

### Day 1: Self-Hosted (Immediate)
- ✅ Complete pre-submission checklist
- ✅ Push to GitHub with assets
- ✅ Test installation
- ✅ Share with team/community

**Available immediately for anyone with GitHub URL!**

### Week 1: Official Marketplace
- 📝 Submit to claudecodecommands.directory
- ⏳ Wait for review (1-7 days)
- 🔄 Address feedback if needed
- ✅ Approved and listed

### Week 2: Community Marketplaces
- 📝 Submit PRs to community catalogs
- ⏳ Wait for maintainer approval
- ✅ Listed in multiple locations

### Ongoing: Promotion
- 📱 Share on social media
- 📝 Write blog post
- 💬 Engage with users
- 🐛 Fix issues
- ✨ Add features

## Post-Submission Maintenance

### Monitor Issues
- Check GitHub Issues regularly
- Respond to user questions
- Fix bugs promptly
- Tag issues appropriately

### Update Documentation
- Keep README current
- Update CHANGELOG for releases
- Improve troubleshooting guides
- Add FAQ based on user questions

### Release Updates
- Follow semantic versioning
- Update version in all manifests:
  - `.claude-plugin/plugin.json`
  - `.claude-plugin/submission-metadata.json`
  - `.claude-plugin/marketplace.json`
  - `Sources/appstoreconnect-mcp/App.swift`
  - `CHANGELOG.md`
- Tag releases in git
- Update marketplace listings

### Engage with Community
- Respond to discussions
- Help users with setup
- Share success stories
- Request feedback
- Incorporate suggestions

## Version Update Process

When releasing v1.1.0:

1. **Update version in all files:**
   ```bash
   # Update version numbers
   # - .claude-plugin/plugin.json
   # - .claude-plugin/submission-metadata.json
   # - .claude-plugin/marketplace.json
   # - Sources/appstoreconnect-mcp/App.swift
   # - CHANGELOG.md
   ```

2. **Update CHANGELOG.md:**
   ```markdown
   ## [1.1.0] - 2025-XX-XX

   ### Added
   - New feature descriptions

   ### Fixed
   - Bug fix descriptions
   ```

3. **Commit and tag:**
   ```bash
   git add .
   git commit -m "chore: bump version to 1.1.0"
   git tag -a v1.1.0 -m "Release v1.1.0"
   git push origin main v1.1.0
   ```

4. **Create GitHub release**

5. **Notify marketplace:**
   - Official marketplace may auto-detect
   - Or submit update via portal
   - Community marketplaces: Submit PR with version bump

## Support Channels

### For Users
- **Issues:** GitHub Issues for bug reports
- **Discussions:** GitHub Discussions for questions
- **Email:** stijn@dooz.io for direct contact
- **Documentation:** README.md, INSTALLATION.md, QUICK_START.md

### For Contributors
- **Contributing:** CONTRIBUTING.md for guidelines
- **Code of Conduct:** Be respectful and professional
- **PRs:** Welcome for bug fixes and features
- **Issues:** Use for feature requests

## Marketing and Promotion

### Launch Announcement

**Social Media Posts:**
```
🚀 Introducing App Store Connect MCP Plugin for Claude Code!

Automate iOS workflows:
✅ Download dSYMs automatically
✅ Upload to Firebase Crashlytics
✅ Check build status
✅ Pure Swift (no Ruby/Fastlane)

Install: /plugin install appstoreconnect-mcp@doozMen

#iOS #Swift #ClaudeCode #AppStoreConnect
```

**Blog Post Topics:**
- "Automating iOS Crash Symbolication with Claude Code"
- "Building a Swift MCP Server for App Store Connect"
- "Pure Swift Alternative to Fastlane for dSYM Management"

**Reddit/Forums:**
- r/swift
- r/iOSProgramming
- Hacker News (Show HN)
- iOS Dev Slack/Discord

### Documentation
- Add to awesome-claude-code lists
- Submit to plugin directories
- Create tutorial videos
- Write integration guides

## Success Metrics

Track these metrics to measure adoption:

- **GitHub Stars:** Community interest
- **Installation Count:** Active usage
- **Issues/Discussions:** Engagement level
- **PR Contributions:** Community involvement
- **Marketplace Downloads:** Distribution reach

## Legal and Compliance

### License
- ✅ MIT License (permissive, commercial-friendly)
- ✅ No attribution required beyond license file
- ✅ Free for all uses

### Privacy
- ✅ No data collection
- ✅ Credentials stay local
- ✅ No external services (except ASC and Firebase when requested)
- ✅ Open source (users can audit code)

### Security
- ✅ Code is open source
- ✅ No hardcoded credentials
- ✅ Secure credential storage practices
- ✅ Regular dependency updates

## Next Steps

**Immediate (Day 1):**
1. Create icon.png (1024x1024px)
2. Capture 5 screenshots
3. Commit assets to repository
4. Update manifest URLs
5. Test self-hosted installation
6. Share with early adopters

**Short-term (Week 1):**
1. Submit to official marketplace
2. Monitor for review feedback
3. Address any issues
4. Promote to iOS developer community

**Medium-term (Week 2-4):**
1. Submit to community marketplaces
2. Write blog post/tutorial
3. Create demo video
4. Gather user feedback
5. Plan v1.1.0 features

**Long-term (Ongoing):**
1. Maintain and update plugin
2. Add new features based on feedback
3. Improve documentation
4. Build community
5. Support users

## Questions?

- **Plugin structure:** See PLUGIN_SUMMARY.md
- **Installation:** See INSTALLATION.md
- **Quick start:** See QUICK_START.md
- **Development:** See CONTRIBUTING.md
- **Contact:** stijn@dooz.io

Good luck with your marketplace submission! 🚀
