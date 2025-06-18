//
//  OAuthManager.swift
//  Maybe
//
//  Created by Josh Pigford on 6/13/25.
//

import SwiftUI
import Foundation
import CryptoKit
import AuthenticationServices
#if os(iOS)
import UIKit
#endif

// Note: This file depends on:
// - MaybeOAuthConfig (OAuth/OAuthConfig.swift)
// - TokenResponse, OAuthError, OAuthErrorResponse (Models/OAuthModels.swift)
// - Data+Extensions (Extensions/Data+Extensions.swift)

// MARK: - OAuth Manager
@MainActor
class MaybeOAuthManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var authSession: ASWebAuthenticationSession?
    private var authContinuation: CheckedContinuation<TokenResponse, Error>?
    private var codeVerifier: String = ""
    private var codeChallenge: String = ""
    private var pendingOAuthContinuation: CheckedContinuation<TokenResponse, Error>?

    func authenticate(scopes: [String] = ["read_write"]) {
        print("🔐 === STARTING OAUTH AUTHENTICATION ===")
        print("   Requested scopes: \(scopes)")
        print("   Client ID: \(MaybeOAuthConfig.clientId)")
        print("   Redirect URI: \(MaybeOAuthConfig.redirectUri)")
        print("   Base URL: \(MaybeOAuthConfig.baseURL)")

        Task {
            isLoading = true
            do {
                print("🔐 Generating PKCE parameters...")
                generatePKCEParameters()

                print("🔐 Building authorization URL...")
                let authURL = buildAuthorizationURL(scopes: scopes)
                print("   Auth URL: \(authURL)")

                print("🔐 Starting OAuth flow...")
                let tokens = try await performAuthorizationFlow(authURL: authURL)

                print("✅ OAuth successful! Setting up app state...")
                self.accessToken = tokens.accessToken
                self.isAuthenticated = true
                self.errorMessage = nil

                print("🔐 Storing tokens securely...")
                try storeTokensSecurely(tokens)
                print("✅ Authentication complete!")
            } catch {
                print("❌ Authentication error: \(error)")
                self.errorMessage = error.localizedDescription
                self.isAuthenticated = false
            }
            isLoading = false
        }
    }
    
    // New method specifically for connecting accounts
    func connectAccount(completion: @escaping (Bool, Error?) -> Void) {
        print("🔐 === STARTING ACCOUNT CONNECTION FLOW ===")
        
        Task {
            isLoading = true
            do {
                // Generate fresh PKCE parameters for this flow
                generatePKCEParameters()
                
                // Build URL for account connection
                var components = URLComponents(string: "\(MaybeOAuthConfig.baseURL)/connections/new")!
                components.queryItems = [
                    URLQueryItem(name: "redirect_uri", value: MaybeOAuthConfig.redirectUri),
                    URLQueryItem(name: "oauth", value: "true")
                ]
                
                guard let connectionURL = components.url else {
                    throw OAuthError.invalidResponse
                }
                
                print("🔐 Starting account connection flow with URL: \(connectionURL)")
                
                // Use a simplified auth session for account connections
                try await performAccountConnectionFlow(connectionURL: connectionURL, completion: completion)
                
            } catch {
                print("❌ Account connection error: \(error)")
                completion(false, error)
            }
            isLoading = false
        }
    }
    
    private func performAccountConnectionFlow(connectionURL: URL, completion: @escaping (Bool, Error?) -> Void) async throws {
        await withCheckedContinuation { continuation in
            authSession = ASWebAuthenticationSession(
                url: connectionURL,
                callbackURLScheme: "maybeapp"
            ) { callbackURL, error in
                if let error = error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        print("🔐 User cancelled account connection")
                        completion(false, nil)
                    } else {
                        print("❌ Account connection error: \(error)")
                        completion(false, error)
                    }
                    continuation.resume()
                    return
                }
                
                // Check if the callback indicates success
                if let callbackURL = callbackURL {
                    print("✅ Account connection callback received: \(callbackURL)")
                    
                    // Parse the callback URL to check for success/error
                    if let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                       let queryItems = components.queryItems {
                        
                        // Check for error in callback
                        if let error = queryItems.first(where: { $0.name == "error" })?.value {
                            print("❌ Account connection failed: \(error)")
                            completion(false, OAuthError.serverError(error))
                        } else {
                            print("✅ Account connection successful")
                            completion(true, nil)
                        }
                    } else {
                        // Assume success if we got a callback without error
                        completion(true, nil)
                    }
                } else {
                    completion(false, OAuthError.invalidCallback)
                }
                
                continuation.resume()
            }
            
            authSession?.presentationContextProvider = self
            authSession?.prefersEphemeralWebBrowserSession = false
            authSession?.start()
        }
    }

    func logout() {
        Task {
            await revokeToken()
            clearStoredTokens()

            self.accessToken = nil
            self.isAuthenticated = false
            self.errorMessage = nil
        }
    }

    func loadStoredTokens() {
        print("🔐 === CHECKING FOR STORED TOKENS ===")

        if let tokens = getStoredTokens() {
            print("✅ Found stored tokens")
            print("   Token expires at: \(tokens.expiresAt)")
            print("   Current time: \(Date())")
            print("   Is expired: \(isTokenExpired(tokens.expiresAt))")

            if !isTokenExpired(tokens.expiresAt) {
                print("✅ Token is still valid, authenticating user")
                self.accessToken = tokens.accessToken
                self.isAuthenticated = true
            } else {
                print("❌ Token has expired, user needs to re-authenticate")
            }
        } else {
            print("❌ No stored tokens found")
        }
    }

    private func generatePKCEParameters() {
        codeVerifier = generateRandomString(length: 128)
        let data = Data(codeVerifier.utf8)
        let hashed = SHA256.hash(data: data)
        codeChallenge = Data(hashed).base64URLEncodedString()
    }

    private func generateRandomString(length: Int) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        return String((0..<length).map { _ in characters.randomElement()! })
    }

    private func buildAuthorizationURL(scopes: [String]) -> URL {
        var components = URLComponents(string: MaybeOAuthConfig.authorizationEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: MaybeOAuthConfig.clientId),
            URLQueryItem(name: "redirect_uri", value: MaybeOAuthConfig.redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: generateRandomString(length: 32)),
            // Add mobile parameter to ensure server redirects properly
            URLQueryItem(name: "display", value: "mobile"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        return components.url!
    }

    private func performAuthorizationFlow(authURL: URL) async throws -> TokenResponse {
        return try await withCheckedThrowingContinuation { continuation in
            // Store continuation for manual callback handling
            self.pendingOAuthContinuation = continuation
            
            print("🔐 Creating ASWebAuthenticationSession...")
            print("   URL: \(authURL)")
            print("   Callback Scheme: maybeapp")
            
            authSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "maybeapp"
            ) { callbackURL, error in
                print("🔐 ASWebAuthenticationSession callback received")
                
                if let error = error {
                    print("❌ Auth session error: \(error)")
                    // Check if user cancelled
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        print("🔐 User cancelled the authentication")
                    }
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL = callbackURL else {
                    print("❌ No callback URL received")
                    continuation.resume(throwing: OAuthError.invalidCallback)
                    return
                }
                
                print("✅ Callback URL received: \(callbackURL)")
                
                guard let code = self.extractAuthorizationCode(from: callbackURL) else {
                    print("❌ Could not extract authorization code from callback URL")
                    continuation.resume(throwing: OAuthError.invalidCallback)
                    return
                }
                
                print("✅ Authorization code extracted: \(code)")

                Task {
                    do {
                        let tokens = try await self.exchangeCodeForTokens(code: code)
                        continuation.resume(returning: tokens)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }

            // Ensure we're on the main thread for UI operations
            Task { @MainActor in
                authSession?.presentationContextProvider = self
                authSession?.prefersEphemeralWebBrowserSession = false
                
                print("🔐 Starting ASWebAuthenticationSession...")
                let started = authSession?.start() ?? false
                print("   Session started: \(started)")
                
                if !started {
                    print("❌ Failed to start ASWebAuthenticationSession")
                    continuation.resume(throwing: OAuthError.invalidResponse)
                }
            }
        }
    }

    private func extractAuthorizationCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return nil }
        return queryItems.first { $0.name == "code" }?.value
    }

    private func exchangeCodeForTokens(code: String) async throws -> TokenResponse {
        let fullURL = MaybeOAuthConfig.tokenEndpoint
        print("🔐 OAuth Token Exchange Details:")
        print("   Method: POST")
        print("   Full URL: \(fullURL)")

        guard let url = URL(string: fullURL) else {
            print("❌ Invalid OAuth URL: \(fullURL)")
            throw OAuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type": "authorization_code",
            "client_id": MaybeOAuthConfig.clientId,
            "code": code,
            "redirect_uri": MaybeOAuthConfig.redirectUri,
            "code_verifier": codeVerifier
        ]

        let bodyString = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

        print("   Headers:")
        print("     Content-Type: application/x-www-form-urlencoded")
        print("   Body: \(bodyString)")

        print("🚀 Making OAuth token request now...")
        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        print("📡 OAuth Response received (took \(String(format: "%.2f", duration))s):")

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid OAuth response type - not HTTPURLResponse")
            throw OAuthError.invalidResponse
        }

        print("   Status Code: \(httpResponse.statusCode)")
        print("   Response Headers:")
        for (key, value) in httpResponse.allHeaderFields {
            print("     \(key): \(value)")
        }
        print("   Response Size: \(data.count) bytes")

        if let responseString = String(data: data, encoding: .utf8) {
            print("   Response Body: \(responseString)")
        } else {
            print("   Response Body: Unable to decode as UTF-8")
        }

        if httpResponse.statusCode == 200 {
            print("✅ OAuth token exchange successful, decoding response...")
            let decoder = JSONDecoder()
            let tokenResponse = try decoder.decode(TokenResponse.self, from: data)
            print("✅ Token decoded successfully - expires in \(tokenResponse.expiresIn) seconds")
            return tokenResponse
        } else {
            print("❌ OAuth token exchange failed with status \(httpResponse.statusCode)")
            let errorResponse = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data)
            throw OAuthError.serverError(errorResponse?.error ?? "HTTP \(httpResponse.statusCode)")
        }
    }

    private func revokeToken() async {
        guard let token = accessToken else { return }
        let url = URL(string: "\(MaybeOAuthConfig.baseURL)/oauth/revoke")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "token": token,
            "client_id": MaybeOAuthConfig.clientId
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        try? await URLSession.shared.data(for: request)
    }

    private func storeTokensSecurely(_ tokens: TokenResponse) throws {
        let encoder = JSONEncoder()
        let tokenData = try encoder.encode(tokens)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "MaybeApp",
            kSecAttrAccount as String: "oauth_tokens",
            kSecValueData as String: tokenData
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("Failed to store tokens securely: \(status)")
            throw OAuthError.serverError("Failed to store tokens securely")
        }
    }

    private func getStoredTokens() -> TokenResponse? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "MaybeApp",
            kSecAttrAccount as String: "oauth_tokens",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(TokenResponse.self, from: data)
    }

    private func clearStoredTokens() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "MaybeApp",
            kSecAttrAccount as String: "oauth_tokens"
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func isTokenExpired(_ expirationDate: Date) -> Bool {
        return Date() >= expirationDate.addingTimeInterval(-300)
    }
    
    // Manual OAuth callback handler for when ASWebAuthenticationSession doesn't intercept the callback
    func handleOAuthCallback(_ url: URL) async {
        print("🔐 Manual OAuth callback handler invoked")
        print("   URL: \(url)")
        
        // Extract the authorization code
        guard let code = extractAuthorizationCode(from: url) else {
            print("❌ Could not extract authorization code from callback URL")
            pendingOAuthContinuation?.resume(throwing: OAuthError.invalidCallback)
            return
        }
        
        print("✅ Authorization code extracted: \(code)")
        
        // If we have a pending continuation, use it
        if let continuation = pendingOAuthContinuation {
            pendingOAuthContinuation = nil
            
            do {
                let tokens = try await exchangeCodeForTokens(code: code)
                continuation.resume(returning: tokens)
            } catch {
                continuation.resume(throwing: error)
            }
        } else {
            // Handle the OAuth callback independently
            do {
                let tokens = try await exchangeCodeForTokens(code: code)
                
                await MainActor.run {
                    self.accessToken = tokens.accessToken
                    self.isAuthenticated = true
                    self.errorMessage = nil
                }
                
                try storeTokensSecurely(tokens)
                print("✅ Manual OAuth authentication complete!")
            } catch {
                print("❌ Manual OAuth authentication error: \(error)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isAuthenticated = false
                }
            }
        }
    }
}

extension MaybeOAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        print("🔐 Providing presentation anchor for ASWebAuthenticationSession")
        #if os(iOS)
        // For iOS 15+, use the first active window scene
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            print("✅ Found key window for presentation")
            return window
        }
        
        // Fallback to any window
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first {
            print("⚠️ Using fallback window for presentation")
            return window
        }
        
        print("❌ No window found for presentation")
        return ASPresentationAnchor()
        #elseif os(macOS)
        return NSApplication.shared.windows.first ?? ASPresentationAnchor()
        #else
        return ASPresentationAnchor()
        #endif
    }
}