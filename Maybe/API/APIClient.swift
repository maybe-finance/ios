//
//  APIClient.swift
//  Maybe
//
//  Created by Josh Pigford on 6/13/25.
//

import Foundation

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
    
    private weak var authManager: MaybeAuthManager?
    
    init(authManager: MaybeAuthManager?) {
        self.authManager = authManager
        print("🌐 API Client initialized with base URL: \(baseURL)")
    }
    
    func updateAuthManager(_ authManager: MaybeAuthManager?) {
        self.authManager = authManager
    }
    
    // MARK: - Authentication Endpoints
    
    func signup(request: SignupRequest) async throws -> AuthResponse {
        let endpoint = "/auth/signup"
        let body = try JSONEncoder().encode(request)
        return try await makeRequest(
            endpoint: endpoint,
            method: "POST",
            body: body,
            responseType: AuthResponse.self,
            requiresAuth: false
        )
    }
    
    func login(request: LoginRequest) async throws -> AuthResponse {
        let endpoint = "/auth/login"
        let body = try JSONEncoder().encode(request)
        
        do {
            return try await makeRequest(
                endpoint: endpoint,
                method: "POST",
                body: body,
                responseType: AuthResponse.self,
                requiresAuth: false
            )
        } catch {
            // Check if it's an MFA required error
            if let data = error as? APIError {
                throw data
            }
            
            // Try to parse error response for MFA
            if let urlError = error as? URLError,
               let errorData = urlError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                if let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: errorData),
                   errorResponse.mfaRequired == true {
                    throw APIError.mfaRequired
                }
            }
            
            throw error
        }
    }
    
    func refreshToken(request: RefreshTokenRequest) async throws -> AuthTokens {
        let endpoint = "/auth/refresh"
        let body = try JSONEncoder().encode(request)
        
        struct RefreshResponse: Codable {
            let accessToken: String
            let refreshToken: String
            let tokenType: String
            let expiresIn: Int
            let createdAt: Int
            
            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case refreshToken = "refresh_token"
                case tokenType = "token_type"
                case expiresIn = "expires_in"
                case createdAt = "created_at"
            }
        }
        
        let response = try await makeRequest(
            endpoint: endpoint,
            method: "POST",
            body: body,
            responseType: RefreshResponse.self,
            requiresAuth: false
        )
        
        return AuthTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            tokenType: response.tokenType,
            expiresIn: response.expiresIn,
            createdAt: response.createdAt
        )
    }
    
    // MARK: - Account Endpoints
    
    func getAccounts(page: Int = 1, perPage: Int = 25) async throws -> AccountsResponse {
        let endpoint = "/accounts?page=\(page)&per_page=\(perPage)"
        print("Making API request to: \(baseURL)\(endpoint)")
        return try await makeRequest(endpoint: endpoint, responseType: AccountsResponse.self)
    }
    
    // MARK: - Test Endpoints
    
    func testAPIConnection() async throws -> String {
        let testEndpoints = ["/accounts", "/user", "/me", "/"]
        
        for endpoint in testEndpoints {
            do {
                print("Testing endpoint: \(baseURL)\(endpoint)")
                let url = URL(string: "\(baseURL)\(endpoint)")!
                var request = URLRequest(url: url)
                
                if let token = authManager?.getAccessToken() {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                
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
    
    // MARK: - Private Methods
    
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        responseType: T.Type,
        requiresAuth: Bool = true
    ) async throws -> T {
        // Check for authentication if required
        if requiresAuth {
            guard let accessToken = authManager?.getAccessToken() else {
                print("❌ API Error: No access token available")
                throw APIError.tokenExpired
            }
            
            print("🔐 Using access token: \(String(accessToken.prefix(20)))...")
            
            // Check if we need to refresh the token
            await authManager?.refreshTokenIfNeeded()
        }
        
        let fullURL = "\(baseURL)\(endpoint)"
        print("🌐 API Request Details:")
        print("   Method: \(method)")
        print("   Full URL: \(fullURL)")
        
        guard let url = URL(string: fullURL) else {
            print("❌ Invalid URL: \(fullURL)")
            throw APIError.unknownError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth header if we have a token
        if requiresAuth, let accessToken = authManager?.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            print("   Authorization: Bearer \(String(accessToken.prefix(20)))...")
        }
        
        if let body = body {
            request.httpBody = body
            print("   Body: \(String(data: body, encoding: .utf8) ?? "Unable to decode body")")
        }
        
        print("🚀 Making API request now...")
        let startTime = Date()
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            print("📡 API Response received (took \(String(format: "%.2f", duration))s):")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type - not HTTPURLResponse")
                throw APIError.unknownError("Invalid response")
            }
            
            print("   Status Code: \(httpResponse.statusCode)")
            print("   Response Size: \(data.count) bytes")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Response Body: \(responseString.prefix(500))...")
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                let result = try decoder.decode(T.self, from: data)
                print("✅ Successfully decoded response of type \(T.self)")
                return result
                
            case 400:
                let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data)
                if let error = errorResponse?.error {
                    if error.contains("Device information") {
                        throw APIError.deviceInfoRequired
                    }
                    throw APIError.unknownError(error)
                }
                throw APIError.unknownError("Bad request")
                
            case 401:
                let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data)
                if errorResponse?.mfaRequired == true {
                    throw APIError.mfaRequired
                }
                if let error = errorResponse?.error, error.contains("Invalid email or password") {
                    throw APIError.invalidCredentials
                }
                throw APIError.tokenExpired
                
            case 403:
                let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data)
                throw APIError.unknownError(errorResponse?.error ?? "Forbidden")
                
            case 422:
                let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data)
                if let errors = errorResponse?.errors {
                    throw APIError.validationErrors(errors)
                }
                throw APIError.unknownError("Validation failed")
                
            case 429:
                throw APIError.unknownError("Rate limit exceeded")
                
            default:
                let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data)
                throw APIError.unknownError(errorResponse?.error ?? "HTTP \(httpResponse.statusCode)")
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}