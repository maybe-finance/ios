//
//  ContentView.swift
//  Maybe
//
//  Created by Josh Pigford on 6/13/25.
//

import SwiftUI

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var authManager: MaybeAuthManager
    @StateObject private var apiClient = MaybeAPIClient(authManager: nil)
    
    var body: some View {
        NavigationView {
            Group {
                if authManager.isAuthenticated {
                    AuthenticatedView()
                        .environmentObject(apiClient)
                } else {
                    LoginView()
                }
            }
            .background(Color(hex: "F0F0F0"))
        }
        .environmentObject(authManager)
        .onAppear {
            // Wire up the bidirectional relationship
            apiClient.updateAuthManager(authManager)
            authManager.apiClient = apiClient
        }
        .onChange(of: authManager.isAuthenticated) { _ in
            // Update API client when auth state changes
            apiClient.updateAuthManager(authManager)
        }
        .alert("Error", isPresented: .constant(authManager.error != nil)) {
            Button("OK") {
                authManager.error = nil
            }
        } message: {
            Text(authManager.error ?? "")
        }
    }
}

#Preview {
    ContentView()
}
