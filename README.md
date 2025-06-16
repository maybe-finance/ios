# Maybe Finance iOS App

A native iOS application for [Maybe Finance](https://maybefinance.com) that provides secure access to your financial accounts through OAuth 2.0 authentication.

**NOTE:** This is almost impossibly early in the dev cycle for this app. It will take quite a bit of work to get it functioning locally but we wanted to go ahead and open-source it.

## Features

- 🔐 **OAuth 2.0 with PKCE** - Secure authentication with Maybe Finance
- 💰 **Account Overview** - View all your financial accounts and balances
- 📱 **Native iOS Experience** - Built with SwiftUI for optimal performance
- 🔒 **Keychain Security** - Secure token storage using iOS Keychain
- 🌐 **RESTful API Integration** - Full integration with Maybe Finance API

## Prerequisites

- **macOS** with Xcode 15.0 or later
- **iOS 16.0+** deployment target
- **Maybe Finance Account** - Sign up at [maybefinance.com](https://maybefinance.com)
- **OAuth Client Credentials** - Contact Maybe Finance team for API access

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/maybe-finance/ios.git
cd maybe-ios
```

### 2. Configure API Credentials

```bash
# Copy the configuration template
cp Config.xcconfig.template Config.xcconfig
```

Edit `Config.xcconfig` with your actual values:

```
MAYBE_OAUTH_CLIENT_ID = your_oauth_client_id_here
MAYBE_BASE_URL = https://app.maybefinance.com
MAYBE_API_BASE_URL = https://app.maybefinance.com/api/v1
MAYBE_OAUTH_REDIRECT_URI = maybeapp://oauth/callback
```

### 3. Configure Xcode Project

1. Open `Maybe.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the "Maybe" target
4. Go to **Build Settings** tab
5. Search for "Configuration Files"
6. Set both **Debug** and **Release** to use `Config.xcconfig`

### 4. Build and Run

1. Select your target device or simulator
2. Press `Cmd+R` or click the "Run" button
3. The app should launch and prompt for Maybe Finance authentication

## Getting API Credentials

To use this app, you'll need OAuth credentials from Maybe Finance:

1. **Contact Maybe Finance** - Reach out to the Maybe team to register your application
2. **Provide Redirect URI** - Use `maybeapp://oauth/callback` as your redirect URI
3. **Receive Client ID** - You'll receive a unique client ID for your app
4. **Configure App** - Add your credentials to `Config.xcconfig`

## Project Structure

```
Maybe.xcodeproj/          # Xcode project file
Maybe/                    # Main app source code
├── API/                  # API client and networking
├── Extensions/           # Swift extensions and utilities
├── Models/              # Data models and structures
├── OAuth/               # OAuth authentication logic
├── Views/               # SwiftUI views and UI components
├── Assets.xcassets/     # App icons and images
├── Info.plist          # App configuration
└── MaybeApp.swift      # App entry point
Config.xcconfig.template  # Configuration template
```

## Architecture

The app follows a clean, modular architecture:

- **SwiftUI Views** - Declarative UI with `@StateObject` and `@EnvironmentObject`
- **OAuth Manager** - Handles authentication flow with PKCE security
- **API Client** - RESTful API communication with proper error handling
- **Secure Storage** - iOS Keychain integration for token persistence
- **Configuration System** - External configuration via `.xcconfig` files

### Key Components

- **`MaybeOAuthManager`** - OAuth 2.0 flow with PKCE implementation
- **`MaybeAPIClient`** - HTTP client for Maybe Finance API
- **`AuthenticatedView`** - Main app interface for logged-in users
- **`LoginView`** - Authentication and onboarding flow

## Development

### Building for Different Environments

Create environment-specific configuration files:

```bash
cp Config.xcconfig.template Config-Dev.xcconfig
cp Config.xcconfig.template Config-Staging.xcconfig
cp Config.xcconfig.template Config-Production.xcconfig
```

Configure different Xcode schemes to use different configuration files for each environment.

### Debugging

The app includes comprehensive logging for development:

- OAuth flow debugging with request/response logging
- API call tracing with timing information
- Error handling with user-friendly messages

Set breakpoints in:
- `MaybeOAuthManager.authenticate()` - OAuth flow
- `MaybeAPIClient.makeRequest()` - API calls
- View `onAppear` methods - UI lifecycle

### Testing

The app includes built-in connection testing:

```swift
// Test API connectivity
try await apiClient.testAPIConnection()
```

## Security

This app implements security best practices:

- **PKCE (Proof Key for Code Exchange)** - Enhanced OAuth security
- **iOS Keychain** - Secure token storage
- **TLS/HTTPS** - All network communication encrypted
- **Token Expiration** - Automatic handling of expired tokens
- **No Hardcoded Secrets** - All sensitive data externalized

## Contributing

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Configure your environment** (copy and edit `Config.xcconfig`)
4. **Make your changes**
5. **Test thoroughly** on device and simulator
6. **Commit your changes** (`git commit -m 'Add amazing feature'`)
7. **Push to the branch** (`git push origin feature/amazing-feature`)
8. **Open a Pull Request**

### Development Guidelines

- Follow Swift style conventions
- Use SwiftUI for all new UI components
- Ensure proper error handling and user feedback
- Test on multiple devices and iOS versions
- Document any new configuration requirements

## Troubleshooting

### "MaybeOAuthClientID not configured" Error

This means your configuration file isn't set up properly:

1. Ensure `Config.xcconfig` exists with your actual values
2. Verify Xcode is using the configuration file in Build Settings
3. Clean build folder (`Cmd+Shift+K`) and rebuild

### OAuth Authentication Fails

1. **Check client ID** - Ensure it matches what Maybe Finance provided
2. **Verify redirect URI** - Must exactly match your registered URI
3. **Check network connection** - Ensure you can reach the API endpoints
4. **Review console logs** - Look for detailed error messages

### API Requests Fail

1. **Check base URL** - Ensure it points to the correct Maybe Finance environment
2. **Verify token** - Check if your access token is valid and not expired
3. **Review API documentation** - Ensure you're using correct endpoints
4. **Check rate limits** - You may be hitting API rate limits

## Copyright & license

Maybe is distributed under an [AGPLv3 license](https://github.com/maybe-finance/ios/blob/main/LICENSE). "Maybe" is a trademark of Maybe Finance, Inc.