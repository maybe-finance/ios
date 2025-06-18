# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a native iOS application for Maybe Finance built with SwiftUI. The app is in early development stages and implements OAuth 2.0 authentication with PKCE for secure access to financial data.

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
# MAYBE_OAUTH_CLIENT_ID = your_oauth_client_id_here
# MAYBE_BASE_URL = https://app.maybefinance.com
# MAYBE_API_BASE_URL = https://app.maybefinance.com/api/v1
# MAYBE_OAUTH_REDIRECT_URI = maybeapp://oauth/callback
```

## Architecture

### Core Components
- **MaybeOAuthManager** (OAuth/MaybeOAuthManager.swift): Handles OAuth 2.0 authentication flow with PKCE implementation. Central authentication manager used throughout the app.
- **MaybeAPIClient** (API/MaybeAPIClient.swift): RESTful API client for all network requests. Implements proper error handling and token management.
- **ContentView** (Views/ContentView.swift): Root view that manages authentication state and navigation between LoginView and AuthenticatedView.

### View Hierarchy
- **ContentView** → Root container managing auth state
  - **LoginView** → Initial onboarding and authentication
  - **AuthenticatedView** → Main app interface with tab navigation
    - **HomeView** → Dashboard with account overview
    - **TimeView, AppsView, ReadingView, ProfileView** → Other main sections

### State Management
- Uses SwiftUI's `@StateObject` and `@EnvironmentObject` for state management
- OAuth manager is passed as environment object to all views
- Keychain storage for secure token persistence

### Security Implementation
- OAuth 2.0 with PKCE for enhanced security
- Tokens stored in iOS Keychain via `KeychainAccess` utility
- All configuration externalized to xcconfig files (never commit secrets)
- Custom URL scheme: `maybeapp://` for OAuth callbacks

## Development Notes

### Important Files
- **Config.xcconfig**: Environment configuration (not in version control)
- **Info.plist**: References environment variables from xcconfig
- **MaybeApp.swift**: App entry point, initializes OAuth manager

### Adding New API Endpoints
1. Add method to `MaybeAPIClient` following existing patterns
2. Use `makeRequest` method for consistent error handling
3. Define response models in `Models/` directory

### SwiftUI Best Practices
- Follow existing view patterns in `Views/` directory
- Use components from `Views/Components/` for consistency
- Maintain tab-based navigation structure in `AuthenticatedView`

### Configuration Requirements
- Xcode must be configured to use Config.xcconfig in Build Settings
- OAuth client ID required from Maybe Finance team
- Bundle identifier: com.maybefinance.Maybe