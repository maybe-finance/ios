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
                                .font(.geistSubheadline)
                                .fontWeight(.light)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else if accounts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "creditcard")
                                .font(.geist(size: 48))
                                .foregroundColor(.secondary)
                            Text("No accounts found")
                                .font(.geistHeadline)
                                .fontWeight(.semibold)
                            Text("Connect your financial accounts to get started")
                                .font(.geistSubheadline)
                                .fontWeight(.light)
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
                            .font(.geistHeadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        Text(currentTime.formatted(.dateTime.hour().minute().second()))
                            .font(.geistMono(size: 48, weight: .ultraLight))
                            .foregroundColor(.primary)

                        Text(currentTime.formatted(.dateTime.weekday(.wide).month().day().year()))
                            .font(.geistSubheadline)
                            .fontWeight(.light)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(16)

                    // Time Zone Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Time Zone")
                            .font(.geistHeadline)
                            .fontWeight(.semibold)

                        HStack {
                            Text(TimeZone.current.identifier)
                                .font(.geistBody)
                                .fontWeight(.medium)
                            Spacer()
                            Text(TimeZone.current.abbreviation() ?? "")
                                .font(.geistSubheadline)
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
                        .font(.geistLargeTitle)
                        .fontWeight(.black)
                        .padding(.top, 20)

                    Text("Manage your connected applications and services")
                        .font(.geistSubheadline)
                        .fontWeight(.light)
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
                                            .font(.geist(size: 32))
                                            .foregroundColor(.secondary)
                                    )

                                Text("App \(index + 1)")
                                    .font(.geistSubheadline)
                                    .fontWeight(.semibold)
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
                        .font(.geistLargeTitle)
                        .fontWeight(.black)
                        .padding(.top, 20)

                    Text("Your reading list and progress")
                        .font(.geistSubheadline)
                        .fontWeight(.light)
                        .foregroundColor(.secondary)

                    // Reading stats
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("12")
                                .font(.geistTitle)
                                .fontWeight(.heavy)
                            Text("Books Read")
                                .font(.geistCaption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)

                        VStack(spacing: 4) {
                            Text("3")
                                .font(.geistTitle)
                                .fontWeight(.heavy)
                            Text("In Progress")
                                .font(.geistCaption)
                                .fontWeight(.medium)
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
                                .font(.geistHeadline)
                                .fontWeight(.semibold)
                            Spacer()
                        }

                        ForEach(0..<3, id: \.self) { index in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 80)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Book Title \(index + 1)")
                                        .font(.geistSubheadline)
                                        .fontWeight(.semibold)
                                    Text("Author Name")
                                        .font(.geistCaption)
                                        .fontWeight(.light)
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
                            .font(.geist(size: 80))
                            .foregroundColor(.blue)

                        Text("Profile")
                            .font(.geist(size: 28, weight: .black))

                        Text("Manage your account and preferences")
                            .font(.geist(size: 15, weight: .light))
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
                                .font(.geist(size: 17, weight: .semibold))
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
                .font(.geist(size: 20))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.geist(size: 15, weight: .semibold))
                Text(subtitle)
                    .font(.geist(size: 12, weight: .light))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.geist(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabIcon(for: index))
                            .font(.geist(size: 22))
                            .foregroundColor(selectedTab == index ? .primary : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(hex: "F0F0F0"))
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return selectedTab == 0 ? "house.fill" : "house"
        case 1: return selectedTab == 1 ? "chart.pie.fill" : "chart.pie"
        case 2: return selectedTab == 2 ? "square.grid.2x2.fill" : "square.grid.2x2"
        case 3: return selectedTab == 3 ? "book.fill" : "book"
        case 4: return selectedTab == 4 ? "person.crop.circle.fill" : "person.crop.circle"
        default: return ""
        }
    }
}

// MARK: - Authenticated View
struct AuthenticatedView: View {
    @EnvironmentObject var oauthManager: MaybeOAuthManager
    @EnvironmentObject var apiClient: MaybeAPIClient
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Content
            Group {
                switch selectedTab {
                case 0:
                    HomeTabView()
                        .environmentObject(apiClient)
                case 1:
                    TimeTabView()
                case 2:
                    AppsTabView()
                case 3:
                    ReadingTabView()
                case 4:
                    ProfileTabView()
                        .environmentObject(oauthManager)
                default:
                    EmptyView()
                }
            }
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
                .background(GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            print("Safe area bottom: \(geometry.safeAreaInsets.bottom)")
                        }
                })
        }
        .ignoresSafeArea(.keyboard)
        .background(Color(hex: "F0F0F0"))
    }
}