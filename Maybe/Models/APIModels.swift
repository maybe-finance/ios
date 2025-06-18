//
//  APIModels.swift
//  Maybe
//
//  Created by Josh Pigford on 6/13/25.
//

import Foundation

// MARK: - API Models
struct AccountsResponse: Codable {
    let accounts: [Account]
    let pagination: Pagination?
}

struct Account: Codable, Identifiable {
    let id: String
    let name: String
    let balance: String // API returns formatted string like "$550,000.00"
    let currency: String
    let classification: String // New field from API response
    let accountType: String
    let institution: String?
    let lastSyncedAt: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case id, name, balance, currency, classification, institution
        case accountType = "account_type"
        case lastSyncedAt = "last_synced_at"
    }

    var lastSyncedDate: Date? {
        guard let lastSyncedAt = lastSyncedAt else { return nil }
        return Date(timeIntervalSince1970: lastSyncedAt)
    }

    var balanceAsDouble: Double {
        // Parse the formatted balance string (e.g., "$550,000.00" -> 550000.0)
        let cleanedBalance = balance.replacingOccurrences(of: "$", with: "")
                                   .replacingOccurrences(of: ",", with: "")
        return Double(cleanedBalance) ?? 0.0
    }

    var formattedBalance: String {
        return balance // Already formatted by the API
    }
}

struct Pagination: Codable {
    let page: Int?
    let perPage: Int?
    let totalCount: Int?
    let totalPages: Int?

    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case totalCount = "total_count"
        case totalPages = "total_pages"
    }
}

// MARK: - API Error Models
struct APIErrorResponse: Codable {
    let error: String
    let message: String
}

enum APIError: LocalizedError {
    case notAuthenticated
    case unauthorized
    case insufficientScope
    case rateLimitExceeded
    case invalidResponse
    case serverError(String)
    case invalidCredentials
    case mfaRequired
    case deviceInfoRequired
    case tokenExpired
    case networkError(Error)
    case validationErrors([String])
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please log in."
        case .unauthorized:
            return "Access token is invalid or expired."
        case .insufficientScope:
            return "Insufficient permissions for this action."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .invalidResponse:
            return "Invalid response from server."
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidCredentials:
            return "Invalid email or password"
        case .mfaRequired:
            return "Two-factor authentication required"
        case .deviceInfoRequired:
            return "Device information is required"
        case .tokenExpired:
            return "Your session has expired"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .validationErrors(let errors):
            return errors.joined(separator: "\n")
        case .unknownError(let message):
            return message
        }
    }
}