//
//  APIClient.swift
//  Maybe
//
//  Created by Josh Pigford on 6/13/25.
//

import Foundation

// Note: This file depends on:
// - Account, AccountsResponse, APIError, APIErrorResponse (Models/APIModels.swift)
// - MaybeOAuthManager (OAuth/OAuthManager.swift)

// MARK: - API Client
@MainActor
class MaybeAPIClient: ObservableObject {
    private let baseURL: String = {
        guard let apiBaseURL = Bundle.main.object(forInfoDictionaryKey: "MaybeAPIBaseURL") as? String,
              !apiBaseURL.isEmpty,
              apiBaseURL != "YOUR_API_BASE_URL_HERE" else {
            fatalError("MaybeAPIBaseURL not configured in Info.plist. Please copy Config.xcconfig.template to Config.xcconfig and configure your values.")
        }
        return apiBaseURL
    }()
    private let oauthManager: MaybeOAuthManager

    init(oauthManager: MaybeOAuthManager) {
        self.oauthManager = oauthManager
        print("🌐 API Client initialized with base URL: \(baseURL)")
    }

    func getAccounts(page: Int = 1, perPage: Int = 25) async throws -> AccountsResponse {
        let endpoint = "/accounts?page=\(page)&per_page=\(perPage)"
        print("Making API request to: \(baseURL)\(endpoint)")
        return try await makeRequest(endpoint: endpoint, responseType: AccountsResponse.self)
    }

    // Alternative method to test different endpoints
    func testAPIConnection() async throws -> String {
        // Try different possible endpoints
        let testEndpoints = ["/accounts", "/user", "/me", "/"]

        for endpoint in testEndpoints {
            do {
                print("Testing endpoint: \(baseURL)\(endpoint)")
                let url = URL(string: "\(baseURL)\(endpoint)")!
                var request = URLRequest(url: url)
                request.setValue("Bearer \(oauthManager.accessToken ?? "")", forHTTPHeaderField: "Authorization")

                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("Endpoint \(endpoint) returned status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response: \(responseString.prefix(200))...")
                    }
                }
            } catch {
                print("Endpoint \(endpoint) failed: \(error)")
            }
        }

        return "API connection test completed"
    }

    private func makeRequest<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let accessToken = oauthManager.accessToken else {
            print("❌ API Error: No access token available")
            throw APIError.notAuthenticated
        }

        let fullURL = "\(baseURL)\(endpoint)"
        print("🌐 API Request Details:")
        print("   Method: \(method)")
        print("   Full URL: \(fullURL)")
        print("   Access Token (first 20 chars): \(String(accessToken.prefix(20)))...")

        guard let url = URL(string: fullURL) else {
            print("❌ Invalid URL: \(fullURL)")
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        print("   Headers:")
        print("     Authorization: Bearer \(String(accessToken.prefix(20)))...")
        print("     Content-Type: application/json")

        if let body = body {
            request.httpBody = body
            print("   Body: \(String(data: body, encoding: .utf8) ?? "Unable to decode body")")
        }

        print("🚀 Making API request now...")
        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        print("📡 API Response received (took \(String(format: "%.2f", duration))s):")

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type - not HTTPURLResponse")
            throw APIError.invalidResponse
        }

        print("   Status Code: \(httpResponse.statusCode)")
        print("   Response Headers:")
        for (key, value) in httpResponse.allHeaderFields {
            print("     \(key): \(value)")
        }
        print("   Response Size: \(data.count) bytes")

        if let responseString = String(data: data, encoding: .utf8) {
            print("   Response Body: \(responseString.prefix(500))...")
        } else {
            print("   Response Body: Unable to decode as UTF-8")
        }

        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970 // Using Unix timestamps like OAuth
            let result = try decoder.decode(T.self, from: data)
            print("✅ Successfully decoded response of type \(T.self)")

            // Special logging for AccountsResponse
            if let accountsResponse = result as? AccountsResponse {
                print("✅ Parsed \(accountsResponse.accounts.count) accounts:")
                for (index, account) in accountsResponse.accounts.enumerated() {
                    print("   Account \(index + 1): \(account.name) - \(account.formattedBalance) (\(account.accountType))")
                }
            }

            return result
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.insufficientScope
        case 429:
            throw APIError.rateLimitExceeded
        default:
            let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.message ?? "HTTP \(httpResponse.statusCode)")
        }
    }
}