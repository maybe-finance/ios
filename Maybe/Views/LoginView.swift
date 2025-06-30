//
//  LoginView.swift
//  Maybe
//
//  Created by Josh Pigford on 6/13/25.
//

import SwiftUI

// MARK: - Custom Button Style
struct GlossyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(
                ZStack {
                    // Base dark background
                    Color(red: 23/255, green: 23/255, blue: 23/255) // #171717
                    
                    // Radial gradient overlay - matching CSS: radial-gradient(2178.93% 86.06% at 0% 20.83%, ...)
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.0), location: 0.0),      // 0% - transparent
                            .init(color: Color.white.opacity(0.10), location: 0.4225),   // 42.25% - 10% opacity
                            .init(color: Color.white.opacity(0.0), location: 1.0)        // 100% - transparent
                        ]),
                        center: UnitPoint(x: 0, y: 0.2083), // at 0% 20.83%
                        startRadius: 0,
                        endRadius: 800 // Large radius for the gradient spread
                    )
                    .blendMode(.lighten)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 34))
            .overlay(
                // Multiple box shadows translated from CSS
                ZStack {
                    // Inner light shadow: 0px 24px 20px -32px rgba(255, 255, 255, 0.90) inset
                    RoundedRectangle(cornerRadius: 34)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.9),
                                    Color.white.opacity(0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                        .blur(radius: 10)
                        .offset(y: 1)
                    
                    // Second inner shadow: 0px 9px 14px -5px rgba(255, 255, 255, 0.30) inset
                    RoundedRectangle(cornerRadius: 34)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 1
                        )
                        .blur(radius: 3)
                    
                    // White top border: 0px 1px 0px 1px rgba(255, 255, 255, 0.30) inset
                    RoundedRectangle(cornerRadius: 34)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.white.opacity(0.3), location: 0),
                                    .init(color: Color.clear, location: 0.3)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .padding(1)
                    
                    // Black border: 0px 0px 0px 1px #000 inset
                    RoundedRectangle(cornerRadius: 34)
                        .strokeBorder(Color.black, lineWidth: 1)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Story Progress Bar
struct StoryProgressBar: View {
    let numberOfStories: Int
    let currentStory: Int
    let progress: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<numberOfStories, id: \.self) { index in
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .cornerRadius(2)

                        // Progress
                        Rectangle()
                            .fill(Color.black)
                            .cornerRadius(2)
                            .frame(width: progressWidth(for: index, in: geometry))
                            .animation(.linear(duration: 0.2), value: progress)
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(.horizontal)
        .padding(.top, 50) // Account for safe area
    }

    private func progressWidth(for index: Int, in geometry: GeometryProxy) -> CGFloat {
        if index < currentStory {
            return geometry.size.width
        } else if index == currentStory {
            return geometry.size.width * progress
        } else {
            return 0
        }
    }
}

// MARK: - Onboarding Story Content
struct OnboardingStory: View {
    let story: OnboardingStoryData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Custom image or Icon/Illustration
            if let imageName = story.imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit) // Changed to .fit to show full image
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .clipped()
            } else {
                story.iconView
                    .frame(height: 200)
                    .padding(.horizontal, 40)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60) // Add space when using iconView
            }

            // Title and Subtitle
            VStack(alignment: .leading, spacing: 8) {
                Text(story.subtitle)
                    .font(Font.custom("Geist-Regular", size: 20))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(story.title)
                    .font(Font.custom("Geist-SemiBold", size: 40))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .tracking(-1.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 30)
            .padding(.top, 30)

            Spacer()
        }
    }
}

// MARK: - Onboarding Story Data
struct OnboardingStoryData {
    let title: String
    let subtitle: String
    let iconView: AnyView
    let imageName: String? // Custom image name from assets
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var authManager: MaybeAuthManager

    // Story navigation
    @State private var currentStory = 0
    @State private var storyProgress: Double = 0
    @State private var timer: Timer?

    // Form states
    @State private var showAuthSheet = false
    @State private var isSignupMode = false

    // Story duration in seconds
    private let storyDuration: Double = 5.0

        // Onboarding stories data
    private let stories: [OnboardingStoryData] = [
        OnboardingStoryData(
            title: "The personal finance app for everyone",
            subtitle: "Meet Maybe",
            iconView: AnyView(
                VStack(spacing: 20) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    HStack(spacing: 12) {
                        ForEach(["dollarsign.circle.fill", "creditcard.fill", "chart.pie.fill"], id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 30))
                                .foregroundColor(.blue.opacity(0.8))
                        }
                    }
                }
            ),
            imageName: "Story1Image" // Replace with your custom image asset name
        ),
                OnboardingStoryData(
            title: "Every account in one place",
            subtitle: "Track anything",
            iconView: AnyView(
                ZStack {
                    // Simulated app icons in a grid
                    VStack(spacing: 20) {
                        HStack(spacing: 20) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.red.opacity(0.8))
                                .frame(width: 60, height: 60)
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green.opacity(0.8))
                                .frame(width: 60, height: 60)
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.8))
                                .frame(width: 60, height: 60)
                        }
                        HStack(spacing: 20) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.yellow.opacity(0.8))
                                .frame(width: 60, height: 60)
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.purple.opacity(0.8))
                                .frame(width: 60, height: 60)
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.orange.opacity(0.8))
                                .frame(width: 60, height: 60)
                        }
                    }

                    // Maybe logo in center
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                        )
                }
            ),
            imageName: "Story2Image" // Replace with your custom image asset name
        ),
                OnboardingStoryData(
            title: "Talk with your money",
            subtitle: "Ask AI anything",
            iconView: AnyView(
                VStack(spacing: 16) {
                    // Chat bubbles
                    HStack {
                        Text("What's my net worth?")
                            .font(Font.custom("Geist-Regular", size: 14))
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(20)
                        Spacer()
                    }

                    HStack {
                        Spacer()
                        Text("How's my crypto doing?")
                            .font(Font.custom("Geist-Regular", size: 14))
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(20)
                    }

                    HStack {
                        Text("Any unusual spending?")
                            .font(Font.custom("Geist-Regular", size: 14))
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(20)
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
            ),
            imageName: "Story3Image" // Replace with your custom image asset name
        ),
        OnboardingStoryData(
            title: "Private. Safe. Zero ads.",
            subtitle: "Secure by default",
            iconView: AnyView(
                VStack(spacing: 20) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)

                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 24))
                            Text("No tracking")
                                .font(Font.custom("Geist-Regular", size: 12))
                        }
                        VStack(spacing: 4) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 24))
                            Text("Encrypted")
                                .font(Font.custom("Geist-Regular", size: 12))
                        }
                        VStack(spacing: 4) {
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 24))
                            Text("Bank-grade")
                                .font(Font.custom("Geist-Regular", size: 12))
                        }
                    }
                    .foregroundColor(.secondary)
                }
            ),
            imageName: "Story4Image" // Replace with your custom image asset name
        )
    ]

        var body: some View {
        ZStack {
            // Background image from launch screen
            Image("LaunchChartBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bars
                StoryProgressBar(
                    numberOfStories: stories.count,
                    currentStory: currentStory,
                    progress: storyProgress
                )

                // Story content
                OnboardingStory(story: stories[currentStory])
                    .id(currentStory) // Force view recreation instead of animation

                // Auth buttons
                VStack(spacing: 12) {
                                        Button(action: {
                        isSignupMode = true
                        showAuthSheet = true
                    }) {
                        Text("Create account")
                            .font(Font.custom("Geist-SemiBold", size: 17))
                    }
                    .buttonStyle(GlossyButtonStyle())
                    .zIndex(1) // Ensure button is above tap areas

                    Button(action: {
                        isSignupMode = false
                        showAuthSheet = true
                    }) {
                        Text("Sign in")
                            .font(Font.custom("Geist-Medium", size: 17))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(25)
                    }
                    .zIndex(1) // Ensure button is above tap areas

                    Text("By continuing, you agree to our\nTerms of Service and Privacy Policy.")
                        .font(Font.custom("Geist-Regular", size: 12))
                        .foregroundColor(Color.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                .background(Color.clear) // Add background to create hit test area
                .contentShape(Rectangle()) // Define the hit test area
            }

            // Tap areas for navigation - exclude button area
            VStack(spacing: 0) {
                // Top area for navigation
                HStack(spacing: 0) {
                    // Left tap area - previous
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            goToPreviousStory()
                        }

                    // Right tap area - next
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            goToNextStory()
                        }
                }
                
                // Bottom area - no tap gestures to allow button interaction
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 200) // Reserve space for buttons
                    .allowsHitTesting(false) // Disable hit testing in button area
            }
            .ignoresSafeArea()
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthenticationSheet(isSignupMode: $isSignupMode)
                .environmentObject(authManager)
        }
    }

    // MARK: - Timer Management

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            storyProgress += 0.05 / storyDuration

            if storyProgress >= 1.0 {
                goToNextStory()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func goToNextStory() {
        stopTimer()

        if currentStory < stories.count - 1 {
            currentStory += 1
            storyProgress = 0
            startTimer()
        } else {
            // Loop back to first story
            currentStory = 0
            storyProgress = 0
            startTimer()
        }
    }

    private func goToPreviousStory() {
        stopTimer()

        if currentStory > 0 {
            currentStory -= 1
            storyProgress = 0
            startTimer()
        }
    }
}

// MARK: - Authentication Sheet
struct AuthenticationSheet: View {
    @EnvironmentObject var authManager: MaybeAuthManager
    @Environment(\.dismiss) var dismiss

    @Binding var isSignupMode: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var confirmPassword = ""
    @State private var otpCode = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Form Fields
                VStack(spacing: 16) {
                    // Name fields for signup
                    if isSignupMode {
                        HStack(spacing: 12) {
                            TextField("First Name", text: $firstName)
                                .textContentType(.givenName)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)

                            TextField("Last Name", text: $lastName)
                                .textContentType(.familyName)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }

                    // Email field
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(Color.gray.opacity(0.1))
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
                    .background(Color.gray.opacity(0.1))
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
                        .background(Color.gray.opacity(0.1))
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
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.top, 20)

                // Error message
                if let error = authManager.error {
                    Text(error)
                        .font(.geist(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
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
            .padding(.horizontal)
            .navigationTitle(isSignupMode ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
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

            // Dismiss sheet on successful login
            if authManager.isAuthenticated {
                dismiss()
            }
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

            // Dismiss sheet on successful signup
            if authManager.isAuthenticated {
                dismiss()
            }
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