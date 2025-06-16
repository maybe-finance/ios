//
//  OAuthConfig.swift
//  Maybe
//
//  Created by Josh Pigford on 6/13/25.
//

import Foundation

// MARK: - OAuth Configuration
struct MaybeOAuthConfig {
    static let clientId: String = {
        guard let clientId = Bundle.main.object(forInfoDictionaryKey: "MaybeOAuthClientID") as? String,
              !clientId.isEmpty,
              clientId != "YOUR_OAUTH_CLIENT_ID_HERE" else {
            fatalError("MaybeOAuthClientID not configured in Info.plist. Please copy Config.xcconfig.template to Config.xcconfig and configure your values.")
        }
        return clientId
    }()

    static let redirectUri: String = {
        guard let redirectUri = Bundle.main.object(forInfoDictionaryKey: "MaybeOAuthRedirectURI") as? String,
              !redirectUri.isEmpty else {
            return "maybeapp://oauth/callback" // Default fallback
        }
        return redirectUri
    }()

    static let baseURL: String = {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "MaybeBaseURL") as? String,
              !baseURL.isEmpty,
              baseURL != "YOUR_BASE_URL_HERE" else {
            fatalError("MaybeBaseURL not configured in Info.plist. Please copy Config.xcconfig.template to Config.xcconfig and configure your values.")
        }
        return baseURL
    }()

    static let authorizationEndpoint = "\(baseURL)/oauth/authorize"
    static let tokenEndpoint = "\(baseURL)/oauth/token"
}