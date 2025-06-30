# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a native iOS application for Maybe Finance built with SwiftUI. The app implements direct API authentication with email/password, signup functionality, and multi-factor authentication (MFA) support.

## Commands

### Build and Run
- Build: Use Xcode's build command (Cmd+B) or the "Build" button
- Run: Use Xcode's run command (Cmd+R) or the "Run" button
- Clean build: Cmd+Shift+K in Xcode

### Testing
- Test API connectivity: The app includes built-in connection testing via `apiClient.testAPIConnection()`
- No unit test framework is currently set up

### Configuration Setup
```bash
# Copy configuration template
cp Config.xcconfig.template Config.xcconfig

# Edit Config.xcconfig with actual values:
# MAYBE_API_BASE_URL = https://app.maybefinance.com/api/v1
```

## Architecture

### Core Components
- **MaybeAuthManager** (Auth/MaybeAuthManager.swift): Handles API-based authentication including login, signup, MFA, and token refresh. Central authentication manager used throughout the app.
- **MaybeAPIClient** (API/APIClient.swift): RESTful API client for all network requests. Implements proper error handling and automatic token refresh.
- **DeviceInfoManager** (Utilities/DeviceInfoManager.swift): Manages device identification and information required for authentication.
- **ContentView** (Views/ContentView.swift): Root view that manages authentication state and navigation between LoginView and AuthenticatedView.

### Authentication Flow
1. **Login**: Email/password authentication with MFA support
2. **Signup**: Account creation with password validation
3. **Token Management**: 30-day access tokens with automatic refresh using refresh tokens
4. **Device Tracking**: Each authentication request includes device information for security

### View Hierarchy
- **ContentView** → Root container managing auth state
  - **LoginView** → Login/signup interface with form validation
  - **AuthenticatedView** → Main app interface with tab navigation
    - **HomeView** → Dashboard with account overview
    - **TimeView, AppsView, ReadingView, ProfileView** → Other main sections

### State Management
- Uses SwiftUI's `@StateObject` and `@EnvironmentObject` for state management
- Auth manager is passed as environment object to all views
- Keychain storage for secure token persistence
- UserDefaults for non-sensitive user data

### Security Implementation
- Direct API authentication with secure token management
- Tokens stored in iOS Keychain
- Automatic token refresh before expiration
- Device ID persistence for consistent device tracking
- Password validation (8+ chars, uppercase, lowercase, number, special char)
- All configuration externalized to xcconfig files (never commit secrets)

## Development Notes

### Important Files
- **Config.xcconfig**: Environment configuration (not in version control)
- **Info.plist**: References environment variables from xcconfig
- **MaybeApp.swift**: App entry point, initializes auth manager
- **AuthModels.swift**: All authentication-related data models

### Adding New API Endpoints
1. Add method to `MaybeAPIClient` following existing patterns
2. Use `makeRequest` method for consistent error handling
3. Define response models in `Models/` directory
4. Ensure proper authentication handling with `requiresAuth` parameter

### Authentication States
- **Not Authenticated**: Shows LoginView
- **MFA Required**: Shows OTP input field
- **Authenticated**: Shows AuthenticatedView with user data
- **Token Expired**: Automatically attempts refresh, logs out if failed

### SwiftUI Best Practices
- Follow existing view patterns in `Views/` directory
- Use components from `Views/Components/` for consistency
- Maintain tab-based navigation structure in `AuthenticatedView`
- Use proper form validation for user inputs

### Configuration Requirements
- Xcode must be configured to use Config.xcconfig in Build Settings
- API base URL must be configured in Config.xcconfig
- Bundle identifier: com.maybefinance.Maybe

# Using Gemini CLI for Large Codebase Analysis

When analyzing large codebases or multiple files that might exceed context limits, use the Gemini CLI with its massive context window. Use `gemini -p` to leverage Google Gemini's large context capacity.

## File and Directory Inclusion Syntax

Use the `@` syntax to include files and directories in your Gemini prompts. The paths should be relative to WHERE you run the
  gemini command:

### Examples:

**Single file analysis:**
gemini -p "@src/main.py Explain this file's purpose and structure"

Multiple files:
gemini -p "@package.json @src/index.js Analyze the dependencies used in the code"

Entire directory:
gemini -p "@src/ Summarize the architecture of this codebase"

Multiple directories:
gemini -p "@src/ @tests/ Analyze test coverage for the source code"

Current directory and subdirectories:
gemini -p "@./ Give me an overview of this entire project"

# Or use --all_files flag:
gemini --all_files -p "Analyze the project structure and dependencies"

Implementation Verification Examples

Check if a feature is implemented:
gemini -p "@src/ @lib/ Has dark mode been implemented in this codebase? Show me the relevant files and functions"

Verify authentication implementation:
gemini -p "@src/ @middleware/ Is JWT authentication implemented? List all auth-related endpoints and middleware"

Check for specific patterns:
gemini -p "@src/ Are there any React hooks that handle WebSocket connections? List them with file paths"

Verify error handling:
gemini -p "@src/ @api/ Is proper error handling implemented for all API endpoints? Show examples of try-catch blocks"

Check for rate limiting:
gemini -p "@backend/ @middleware/ Is rate limiting implemented for the API? Show the implementation details"

Verify caching strategy:
gemini -p "@src/ @lib/ @services/ Is Redis caching implemented? List all cache-related functions and their usage"

Check for specific security measures:
gemini -p "@src/ @api/ Are SQL injection protections implemented? Show how user inputs are sanitized"

Verify test coverage for features:
gemini -p "@src/payment/ @tests/ Is the payment processing module fully tested? List all test cases"

When to Use Gemini CLI

Use gemini -p when:
- Analyzing entire codebases or large directories
- Comparing multiple large files
- Need to understand project-wide patterns or architecture
- Current context window is insufficient for the task
- Working with files totaling more than 100KB
- Verifying if specific features, patterns, or security measures are implemented
- Checking for the presence of certain coding patterns across the entire codebase

Important Notes

- Paths in @ syntax are relative to your current working directory when invoking gemini
- The CLI will include file contents directly in the context
- No need for --yolo flag for read-only analysis
- Gemini's context window can handle entire codebases that would overflow Claude's context
- When checking implementations, be specific about what you're looking for to get accurate results