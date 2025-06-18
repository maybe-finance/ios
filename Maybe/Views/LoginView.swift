//
//  LoginView.swift
//  Maybe
//
//  Created by Josh Pigford on 6/13/25.
//

import SwiftUI

// Note: This file depends on:
// - MaybeOAuthManager (OAuth/OAuthManager.swift)

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var oauthManager: MaybeOAuthManager

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.geist(size: 80))
                .foregroundColor(.blue)

            Text("Maybe Finance")
                .font(.geist(size: 34, weight: .black))

            Text("Connect your Maybe account to view your financial data")
                .font(.geist(size: 17, weight: .light))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button(action: {
                oauthManager.authenticate(scopes: ["read_write"])
            }) {
                HStack {
                    if oauthManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "link")
                    }
                    Text("Connect Maybe Account")
                        .font(.geist(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(oauthManager.isLoading)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}