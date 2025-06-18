//
//  LoginView.swift
//  Maybe
//
//  Created by Josh Pigford on 6/13/25.
//

import SwiftUI

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var authManager: MaybeAuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var confirmPassword = ""
    @State private var otpCode = ""
    
    @State private var isSignupMode = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Logo and Title
            VStack(spacing: 20) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.geist(size: 80))
                    .foregroundColor(.blue)
                
                Text("Maybe Finance")
                    .font(.geist(size: 34, weight: .black))
                
                Text(isSignupMode ? "Create your account" : "Sign in to your account")
                    .font(.geist(size: 17, weight: .light))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            // Form Fields
            VStack(spacing: 16) {
                // Name fields for signup
                if isSignupMode {
                    HStack(spacing: 12) {
                        TextField("First Name", text: $firstName)
                            .textContentType(.givenName)
                            .autocapitalization(.words)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        TextField("Last Name", text: $lastName)
                            .textContentType(.familyName)
                            .autocapitalization(.words)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                }
                
                // Email field
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                // Password field
                HStack {
                    if showPassword {
                        TextField("Password", text: $password)
                            .textContentType(isSignupMode ? .newPassword : .password)
                    } else {
                        SecureField("Password", text: $password)
                            .textContentType(isSignupMode ? .newPassword : .password)
                    }
                    
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Confirm password for signup
                if isSignupMode {
                    HStack {
                        if showConfirmPassword {
                            TextField("Confirm Password", text: $confirmPassword)
                        } else {
                            SecureField("Confirm Password", text: $confirmPassword)
                        }
                        
                        Button(action: { showConfirmPassword.toggle() }) {
                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // MFA code field
                if authManager.isMFARequired && !isSignupMode {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Two-Factor Authentication")
                            .font(.geist(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextField("6-digit code", text: $otpCode)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
            
            // Error message
            if let error = authManager.error {
                Text(error)
                    .font(.geist(size: 14))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Action button
            Button(action: {
                if isSignupMode {
                    handleSignup()
                } else {
                    handleLogin()
                }
            }) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isSignupMode ? "person.badge.plus" : "arrow.right.circle.fill")
                    }
                    Text(isSignupMode ? "Create Account" : "Sign In")
                        .font(.geist(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!isFormValid || authManager.isLoading)
            .padding(.horizontal)
            
            // Toggle between login and signup
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSignupMode.toggle()
                    clearForm()
                }
            }) {
                HStack {
                    Text(isSignupMode ? "Already have an account?" : "Don't have an account?")
                        .foregroundColor(.secondary)
                    Text(isSignupMode ? "Sign In" : "Sign Up")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
                .font(.geist(size: 15))
            }
            
            Spacer()
        }
        .ignoresSafeArea(.keyboard)
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        if isSignupMode {
            return !email.isEmpty &&
                   !password.isEmpty &&
                   !firstName.isEmpty &&
                   !lastName.isEmpty &&
                   password == confirmPassword &&
                   password.count >= 8
        } else {
            if authManager.isMFARequired {
                return !email.isEmpty && !password.isEmpty && otpCode.count == 6
            }
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private func handleLogin() {
        Task {
            await authManager.login(
                email: email,
                password: password,
                otpCode: authManager.isMFARequired ? otpCode : nil
            )
        }
    }
    
    private func handleSignup() {
        // Validate password first
        let passwordErrors = MaybeAuthManager.validatePassword(password)
        if !passwordErrors.isEmpty {
            authManager.error = passwordErrors.joined(separator: "\n")
            return
        }
        
        if password != confirmPassword {
            authManager.error = "Passwords do not match"
            return
        }
        
        Task {
            await authManager.signup(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        firstName = ""
        lastName = ""
        confirmPassword = ""
        otpCode = ""
        authManager.error = nil
        authManager.isMFARequired = false
    }
}