# Contributing to App Store Connect MCP Plugin

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Setup](#development-setup)
4. [Making Changes](#making-changes)
5. [Testing](#testing)
6. [Submitting Changes](#submitting-changes)
7. [Code Style](#code-style)
8. [Plugin Development](#plugin-development)

## Code of Conduct

This project follows a simple code of conduct:

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Keep discussions technical and professional

## Getting Started

### Prerequisites

- macOS 13.0 or later
- Swift 6.0 or later (Xcode 16+)
- Git
- App Store Connect API credentials for testing
- Firebase CLI (optional, for Crashlytics features)

### Fork and Clone

1. **Fork the repository** on GitHub
2. **Clone your fork:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/asc-mcp.git
   cd asc-mcp
   ```
3. **Add upstream remote:**
   ```bash
   git remote add upstream https://github.com/doozMen/asc-mcp.git
   ```

## Development Setup

### 1. Build the Project

```bash
# Debug build
xcrun swift build

# Release build
xcrun swift build -c release
```

### 2. Run Tests

```bash
xcrun swift test
```

### 3. Install Locally

```bash
./install.sh
```

### 4. Set Up Test Credentials

Create a `.env` file (DO NOT commit this):

```bash
cat > .env << 'EOF'
export ASC_KEY_ID="YOUR_TEST_KEY_ID"
export ASC_ISSUER_ID="YOUR_TEST_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="/path/to/test/AuthKey.p8"
EOF

# Load environment
source .env
```

### 5. Test Manually

```bash
appstoreconnect-mcp --log-level debug
```

## Making Changes

### Branch Naming

Use descriptive branch names:

- `feature/add-new-tool` - New features
- `fix/authentication-error` - Bug fixes
- `docs/update-readme` - Documentation
- `refactor/clean-error-handling` - Code refactoring
- `test/add-unit-tests` - Test additions

### Commit Messages

Follow conventional commit format:

```
type(scope): subject

body (optional)

footer (optional)
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(tools): add list_testflight_builds tool

Add new MCP tool to list TestFlight builds with beta review status.
Includes unit tests and documentation updates.

Closes #42
```

```
fix(auth): handle JWT expiration gracefully

Previously, expired JWTs caused crashes. Now they trigger
automatic token refresh with proper error messages.
```

## Testing

### Unit Tests

Add tests for all new functionality:

```swift
@Test("List apps filters by bundle ID correctly")
func testListAppsFiltering() async throws {
    // Test implementation
}
```

Run tests:
```bash
swift test
```

### Integration Tests

For features requiring App Store Connect API:

1. Use test credentials
2. Test against real API (carefully)
3. Mock responses for CI/CD

### Manual Testing

Test with Claude Code:

1. Build and install locally
2. Create local marketplace for plugin
3. Test all slash commands
4. Verify agent behavior
5. Check error handling

## Submitting Changes

### Before Submitting

1. **Ensure all tests pass:**
   ```bash
   swift test
   ```

2. **Format code:**
   ```bash
   swift format format -p -r -i Sources Tests Package.swift
   ```

3. **Lint code:**
   ```bash
   swift format lint -s -p -r Sources Tests Package.swift
   ```

4. **Update documentation:**
   - Update README.md if needed
   - Update CHANGELOG.md
   - Add/update inline code documentation
   - Update plugin commands/agents if needed

5. **Test locally:**
   - Build in release mode
   - Test with Claude Code
   - Verify all features work

### Pull Request Process

1. **Push your branch:**
   ```bash
   git push origin feature/your-feature
   ```

2. **Create Pull Request on GitHub**

3. **PR Description should include:**
   - What changed and why
   - Testing performed
   - Screenshots (if UI/plugin changes)
   - Related issues (if any)

4. **PR Template:**
   ```markdown
   ## Summary
   Brief description of changes

   ## Changes
   - Bullet list of specific changes
   - Include new files, modified files

   ## Testing
   - How was this tested?
   - Manual testing steps
   - Unit test coverage

   ## Documentation
   - [ ] Updated README.md
   - [ ] Updated CHANGELOG.md
   - [ ] Updated inline docs
   - [ ] Updated plugin commands/agents

   ## Checklist
   - [ ] Tests pass locally
   - [ ] Code formatted with swift-format
   - [ ] No lint errors
   - [ ] Documentation updated
   - [ ] Tested with Claude Code

   ## Related Issues
   Closes #123
   ```

5. **Wait for review**
   - Address review comments
   - Push updates to same branch
   - Request re-review when ready

## Code Style

### Swift Style Guide

Follow Swift API Design Guidelines and these project conventions:

#### General

- Use Swift 6.0 strict concurrency
- Prefer actors for mutable state
- Use async/await (no callbacks)
- Use structured concurrency
- Comprehensive error handling

#### Naming

```swift
// Types: PascalCase
actor AppStoreConnectClient { }
struct BuildInfo { }
enum ToolError: Error { }

// Functions/methods: camelCase
func listApps(bundleIDFilter: String?) async throws -> [App]
func downloadDSYMs(buildID: String) async throws -> URL

// Properties: camelCase
let keyID: String
var isAuthenticated: Bool

// Constants: camelCase
let defaultTimeout = 30.0
let maxRetries = 3
```

#### Documentation

Use Swift DocC format:

```swift
/// Lists all apps from App Store Connect.
///
/// This method queries the App Store Connect API and returns basic information
/// about all apps accessible with the provided credentials.
///
/// - Parameter bundleIDFilter: Optional bundle ID prefix to filter results
/// - Returns: Array of `App` objects
/// - Throws: `ToolError` if authentication fails or API returns error
func listApps(bundleIDFilter: String? = nil) async throws -> [App] {
    // Implementation
}
```

#### Error Handling

```swift
// Define specific errors
enum ToolError: Error, LocalizedError {
    case missingParameter(String)
    case authenticationFailed
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingParameter(let param):
            return "Missing required parameter: \(param)"
        case .authenticationFailed:
            return "Authentication failed. Check credentials."
        case .apiError(let code, let message):
            return "API error \(code): \(message)"
        }
    }
}

// Use proper error propagation
func someFunction() async throws -> Result {
    guard let value = optionalValue else {
        throw ToolError.missingParameter("value")
    }
    return try await performOperation(value)
}
```

#### Logging

```swift
import Logging

let logger = Logger(label: "component-name")

// Use appropriate levels
logger.debug("Detailed debug information")
logger.info("High-level operation status")
logger.warning("Non-fatal issues")
logger.error("Operation failures")
logger.critical("Fatal errors")

// Include context
logger.info("Starting operation",
           metadata: [
               "appID": "\(appID)",
               "operation": "download"
           ])
```

#### Formatting

Use swift-format (built-in with Swift 6):

```bash
# Format files
swift format format -p -r -i Sources Tests Package.swift

# Check formatting
swift format lint -s -p -r Sources Tests Package.swift
```

## Plugin Development

### Adding New Slash Commands

1. **Create command file:**
   ```bash
   touch commands/new-command.md
   ```

2. **Add frontmatter and content:**
   ```markdown
   ---
   description: Brief description of what this command does
   ---

   # Command Name

   Detailed instructions for Claude on how to execute this command.
   ```

3. **Update plugin.json if needed** (commands auto-discover from directory)

4. **Test command:**
   - Install plugin locally
   - Use `/new-command` in Claude Code
   - Verify behavior

### Adding New Agents

1. **Create agent file:**
   ```bash
   touch agents/new-agent.md
   ```

2. **Add frontmatter and content:**
   ```markdown
   ---
   description: Agent specialization
   capabilities: ["capability1", "capability2"]
   ---

   # Agent Name

   Expertise and invocation context.
   ```

3. **Test agent:**
   - Install plugin locally
   - Trigger agent invocation
   - Verify agent activates correctly

### Adding New MCP Tools

1. **Create tool file:**
   ```swift
   // Sources/appstoreconnect-mcp/Tools/NewTool.swift
   import MCP

   extension MCPServer {
       func newTool() -> Tool {
           Tool(
               name: "new_tool",
               description: "Tool description",
               inputSchema: .object(
                   properties: [
                       "param": .string(description: "Parameter description")
                   ],
                   required: ["param"]
               )
           ) { [weak self] arguments in
               // Implementation
           }
       }
   }
   ```

2. **Register in MCPServer:**
   ```swift
   // In MCPServer.swift init
   tools.append(newTool())
   ```

3. **Add tests:**
   ```swift
   @Test("New tool handles parameters correctly")
   func testNewTool() async throws {
       // Test implementation
   }
   ```

4. **Update documentation:**
   - Add to README.md
   - Update CHANGELOG.md
   - Add usage examples

## Questions?

- **General questions:** [GitHub Discussions](https://github.com/doozMen/asc-mcp/discussions)
- **Bug reports:** [GitHub Issues](https://github.com/doozMen/asc-mcp/issues)
- **Security issues:** Email stijn@dooz.io privately

Thank you for contributing!
