//
//  ContentView.swift
//  Maybe
//
//  Created by Josh Pigford on 6/13/25.
//

import SwiftUI

// The original code has been refactored into separate files:
// - OAuth/OAuthConfig.swift
// - OAuth/OAuthManager.swift
// - Models/OAuthModels.swift
// - Models/APIModels.swift
// - Extensions/Data+Extensions.swift
// - API/APIClient.swift
// - Views/LoginView.swift
// - Views/AuthenticatedView.swift

// Note: In Xcode, these files will be automatically included in the same module
// and their types will be available to ContentView.swift

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var oauthManager = MaybeOAuthManager()
    @StateObject private var apiClient: MaybeAPIClient

    init() {
        let oauth = MaybeOAuthManager()
        _oauthManager = StateObject(wrappedValue: oauth)
        _apiClient = StateObject(wrappedValue: MaybeAPIClient(oauthManager: oauth))
    }

    var body: some View {
        NavigationView {
            Group {
                if oauthManager.isAuthenticated {
                    AuthenticatedView()
                        .environmentObject(apiClient)
                } else {
                    LoginView()
                }
            }
            .background(Color(hex: "F0F0F0"))
        }
        .environmentObject(oauthManager)
        .onAppear {
            oauthManager.loadStoredTokens()
        }
        .alert("Error", isPresented: .constant(oauthManager.errorMessage != nil)) {
            Button("OK") {
                oauthManager.errorMessage = nil
            }
        } message: {
            Text(oauthManager.errorMessage ?? "")
        }
    }
}

#Preview {
    ContentView()
}
