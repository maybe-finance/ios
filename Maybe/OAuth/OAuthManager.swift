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
    private var codeVerifier: String = ""
    private var codeChallenge: String = ""

    func authenticate(scopes: [String] = ["read"]) {
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
            URLQueryItem(name: "state", value: generateRandomString(length: 32))
        ]
        return components.url!
    }

    private func performAuthorizationFlow(authURL: URL) async throws -> TokenResponse {
        return try await withCheckedThrowingContinuation { continuation in
            authSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "maybeapp"
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL = callbackURL,
                      let code = self.extractAuthorizationCode(from: callbackURL) else {
                    continuation.resume(throwing: OAuthError.invalidCallback)
                    return
                }

                Task {
                    do {
                        let tokens = try await self.exchangeCodeForTokens(code: code)
                        continuation.resume(returning: tokens)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }

            authSession?.presentationContextProvider = self
            authSession?.prefersEphemeralWebBrowserSession = false
            authSession?.start()
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
}

extension MaybeOAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(iOS)
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
        #elseif os(macOS)
        return NSApplication.shared.windows.first ?? ASPresentationAnchor()
        #else
        return ASPresentationAnchor()
        #endif
    }
}