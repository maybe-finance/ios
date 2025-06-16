//
//  OAuthModels.swift
//  Maybe
//
//  Created by Josh Pigford on 6/13/25.
//

import Foundation

// MARK: - OAuth Models
struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String
    let createdAt: TimeInterval

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
        case createdAt = "created_at"
    }

    var expiresAt: Date {
        let baseDate = Date(timeIntervalSince1970: createdAt)
        return baseDate.addingTimeInterval(TimeInterval(expiresIn))
    }
}

struct OAuthErrorResponse: Codable {
    let error: String
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
}

enum OAuthError: LocalizedError {
    case invalidCallback
    case invalidResponse
    case serverError(String)
    case tokenExpired

    var errorDescription: String? {
        switch self {
        case .invalidCallback:
            return "Invalid OAuth callback received"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return "Server error: \(message)"
        case .tokenExpired:
            return "Access token has expired"
        }
    }
}