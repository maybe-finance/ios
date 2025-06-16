//
//  AuthenticatedView.swift
//  Maybe
//
//  Created by Josh Pigford on 6/13/25.
//

import SwiftUI

// Note: This file depends on:
// - MaybeOAuthManager (OAuth/OAuthManager.swift)
// - MaybeAPIClient (API/APIClient.swift)
// - Account (Models/APIModels.swift)

// MARK: - Home Tab View
struct HomeTabView: View {
    @EnvironmentObject var apiClient: MaybeAPIClient
    @State private var accounts: [Account] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Top Header
            TopHeaderView()

            // Main Content
            ScrollView {
                LazyVStack(spacing: 16) {
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading your accounts...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else if accounts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No accounts found")
                                .font(.headline)
                            Text("Connect your financial accounts to get started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        .padding(.horizontal, 32)
                    } else {
                        ForEach(accounts) { account in
                            AccountCardView(account: account)
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.top, 16)
            }
            .refreshable {
                await loadAccounts()
            }
        }
        .onAppear {
            Task {
                await loadAccounts()
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadAccounts() async {
        await MainActor.run {
            isLoading = true
        }

        do {
            let response = try await apiClient.getAccounts()
            await MainActor.run {
                self.accounts = response.accounts
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Time Tab View
struct TimeTabView: View {
    @State private var currentTime = Date()

    var body: some View {
        VStack(spacing: 0) {
            // Top Header
            TopHeaderView()

            // Main Content
            ScrollView {
                VStack(spacing: 24) {
                    // Current Time Display
                    VStack(spacing: 8) {
                        Text("Current Time")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(currentTime.formatted(.dateTime.hour().minute().second()))
                            .font(.system(size: 48, weight: .light, design: .monospaced))
                            .foregroundColor(.primary)

                        Text(currentTime.formatted(.dateTime.weekday(.wide).month().day().year()))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(16)

                    // Time Zone Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Time Zone")
                            .font(.headline)

                        HStack {
                            Text(TimeZone.current.identifier)
                                .font(.body)
                            Spacer()
                            Text(TimeZone.current.abbreviation() ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
        }
        .onAppear {
            // Update time every second
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                currentTime = Date()
            }
        }
    }
}

// MARK: - Apps Tab View
struct AppsTabView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Top Header
            TopHeaderView()

            // Main Content
            ScrollView {
                VStack(spacing: 16) {
                    Text("Apps & Services")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)

                    Text("Manage your connected applications and services")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // Grid of app placeholders
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        ForEach(0..<6, id: \.self) { index in
                            VStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 80)
                                    .overlay(
                                        Image(systemName: "app")
                                            .font(.system(size: 32))
                                            .foregroundColor(.secondary)
                                    )

                                Text("App \(index + 1)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Reading Tab View
struct ReadingTabView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Top Header
            TopHeaderView()

            // Main Content
            ScrollView {
                VStack(spacing: 20) {
                    Text("Reading")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)

                    Text("Your reading list and progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Reading stats
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("12")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Books Read")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)

                        VStack(spacing: 4) {
                            Text("3")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("In Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)

                    // Reading list placeholder
                    VStack(spacing: 12) {
                        HStack {
                            Text("Currently Reading")
                                .font(.headline)
                            Spacer()
                        }

                        ForEach(0..<3, id: \.self) { index in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 80)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Book Title \(index + 1)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Author Name")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    ProgressView(value: 0.3 + Double(index) * 0.2)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Profile Tab View
struct ProfileTabView: View {
    @EnvironmentObject var oauthManager: MaybeOAuthManager

    var body: some View {
        VStack(spacing: 0) {
            // Top Header
            TopHeaderView()

            // Main Content
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)

                        Text("Profile")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Manage your account and preferences")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)

                    // Settings Options
                    VStack(spacing: 12) {
                        ProfileOptionRow(icon: "gear", title: "Settings", subtitle: "App preferences and configuration")
                        ProfileOptionRow(icon: "bell", title: "Notifications", subtitle: "Manage notification preferences")
                        ProfileOptionRow(icon: "lock", title: "Privacy & Security", subtitle: "Control your privacy settings")
                        ProfileOptionRow(icon: "questionmark.circle", title: "Help & Support", subtitle: "Get help and contact support")
                    }
                    .padding(.horizontal, 16)

                    // Logout Button
                    Button(action: {
                        oauthManager.logout()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Logout")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Profile Option Row Component
struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Authenticated View
struct AuthenticatedView: View {
    @EnvironmentObject var oauthManager: MaybeOAuthManager
    @EnvironmentObject var apiClient: MaybeAPIClient
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTabView()
                .environmentObject(apiClient)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)

            TimeTabView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "clock.fill" : "clock")
                    Text("Time")
                }
                .tag(1)

            AppsTabView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "square.grid.2x2.fill" : "square.grid.2x2")
                    Text("Apps")
                }
                .tag(2)

            ReadingTabView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "book.fill" : "book")
                    Text("Reading")
                }
                .tag(3)

            ProfileTabView()
                .environmentObject(oauthManager)
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.primary)
    }
}