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
    let isResetting: Bool

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
                            .animation(isResetting ? nil : .linear(duration: 0.2), value: progress)
                            .animation(isResetting ? nil : .linear(duration: 0.2), value: currentStory)
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
                    .font(.geist(size: 20))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(story.title)
                    .font(.geist(size: 40, weight: .semibold))
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
    @State private var isResetting = false

    // Navigation states
    @State private var showSignIn = false
    @State private var showSignUp = false

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
        NavigationStack {
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
                    progress: storyProgress,
                    isResetting: isResetting
                )

                // Story content
                OnboardingStory(story: stories[currentStory])
                    .id(currentStory) // Force view recreation instead of animation

                // Auth buttons
                VStack(spacing: 12) {
                    NavigationLink(destination: SignupFlowView()
                        .environmentObject(authManager)
                        .navigationBarHidden(true)) {
                        Text("Create account")
                            .font(.geist(size: 17, weight: .semibold))
                    }
                    .buttonStyle(GlossyButtonStyle())
                    .zIndex(1) // Ensure button is above tap areas

                    NavigationLink(destination: AuthenticationView(isSignupMode: false)
                        .environmentObject(authManager)
                        .navigationBarHidden(true)) {
                        Text("Sign in")
                            .font(.geist(size: 17, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(25)
                    }
                    .zIndex(1) // Ensure button is above tap areas

                    Text("By continuing, you agree to our\nTerms of Service and Privacy Policy.")
                        .font(.geist(size: 12))
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
            .navigationBarHidden(true)
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
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
            isResetting = true
            currentStory = 0
            storyProgress = 0
            
            // Reset the flag after a short delay to allow the view to update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isResetting = false
            }
            
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

// MARK: - Authentication View
struct AuthenticationView: View {
    @EnvironmentObject var authManager: MaybeAuthManager
    @Environment(\.dismiss) var dismiss

    @State var isSignupMode: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var confirmPassword = ""
    @State private var otpCode = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    // Focus states
    @FocusState private var emailFieldFocused: Bool
    @FocusState private var passwordFieldFocused: Bool
    @FocusState private var firstNameFieldFocused: Bool
    @FocusState private var lastNameFieldFocused: Bool
    @FocusState private var confirmPasswordFieldFocused: Bool
    @FocusState private var otpFieldFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(red: 245/255, green: 245/255, blue: 245/255)
                    .ignoresSafeArea()
                    
                VStack(spacing: 0) {
                    // Navigation bar with buttons
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 32, height: 32)
                                .background(Color(red: 229/255, green: 229/255, blue: 229/255))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // TODO: Show help
                        }) {
                            Image(systemName: "questionmark")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 32, height: 32)
                                .background(Color(red: 229/255, green: 229/255, blue: 229/255))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10) // Minimal top padding
                    .padding(.bottom, 20)
                    
                    // Custom title
                    HStack {
                        Text(isSignupMode ? "Create Account" : "Sign in")
                            .font(.geist(size: 34, weight: .semibold))
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    
                    // Header with subtitle
                    if !isSignupMode {
                        HStack {
                            Text("Or Create Account")
                                .font(.geist(size: 17, weight: .regular))
                                .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // Name fields for signup
                        if isSignupMode {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("First Name")
                                        .font(.geist(size: 13, weight: .medium))
                                        .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                                        .padding(.horizontal, 20)
                                        .padding(.top, 16)
                                        .padding(.bottom, 8)
                                    
                                    TextField("Enter first name", text: $firstName)
                                        .textContentType(.givenName)
                                        .font(.geist(size: 17))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 16)
                                }
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(red: 229/255, green: 229/255, blue: 229/255), lineWidth: 1)
                                        .padding(1)
                                )

                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Last Name")
                                        .font(.geist(size: 13, weight: .medium))
                                        .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                                        .padding(.horizontal, 20)
                                        .padding(.top, 16)
                                        .padding(.bottom, 8)
                                    
                                    TextField("Enter last name", text: $lastName)
                                        .textContentType(.familyName)
                                        .font(.geist(size: 17))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 16)
                                }
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(red: 229/255, green: 229/255, blue: 229/255), lineWidth: 1)
                                        .padding(1)
                                )
                            }
                        }

                        // Email field
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Email")
                                .font(.geist(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                            
                            TextField("Enter email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .font(.geist(size: 17))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                                .focused($emailFieldFocused)
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(emailFieldFocused ? Color(red: 11/255, green: 11/255, blue: 11/255) : Color(red: 11/255, green: 11/255, blue: 11/255).opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: emailFieldFocused ? Color(red: 11/255, green: 11/255, blue: 11/255).opacity(0.05) : Color(red: 11/255, green: 11/255, blue: 11/255).opacity(0.06), radius: emailFieldFocused ? 4 : 1, x: 0, y: emailFieldFocused ? 0 : 1)

                        // Password field
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Password")
                                .font(.geist(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                            
                            HStack {
                                if showPassword {
                                    TextField("Enter password", text: $password)
                                        .textContentType(isSignupMode ? .newPassword : .password)
                                        .font(.geist(size: 17))
                                        .foregroundColor(.black)
                                        .focused($passwordFieldFocused)
                                } else {
                                    SecureField("Enter password", text: $password)
                                        .textContentType(isSignupMode ? .newPassword : .password)
                                        .font(.geist(size: 17))
                                        .foregroundColor(.black)
                                        .focused($passwordFieldFocused)
                                }

                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                                        .font(.system(size: 18))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(passwordFieldFocused ? Color(red: 11/255, green: 11/255, blue: 11/255) : Color(red: 11/255, green: 11/255, blue: 11/255).opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: passwordFieldFocused ? Color(red: 11/255, green: 11/255, blue: 11/255).opacity(0.05) : Color(red: 11/255, green: 11/255, blue: 11/255).opacity(0.06), radius: passwordFieldFocused ? 4 : 1, x: 0, y: passwordFieldFocused ? 0 : 1)

                        // Confirm password for signup
                        if isSignupMode {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Confirm Password")
                                    .font(.geist(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                                    .padding(.bottom, 8)
                                
                                HStack {
                                    if showConfirmPassword {
                                        TextField("Confirm password", text: $confirmPassword)
                                            .font(.geist(size: 17))
                                            .foregroundColor(.black)
                                            .focused($confirmPasswordFieldFocused)
                                    } else {
                                        SecureField("Confirm password", text: $confirmPassword)
                                            .font(.geist(size: 17))
                                            .foregroundColor(.black)
                                            .focused($confirmPasswordFieldFocused)
                                    }

                                    Button(action: { showConfirmPassword.toggle() }) {
                                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                            .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                                            .font(.system(size: 18))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(confirmPasswordFieldFocused ? Color(red: 11/255, green: 11/255, blue: 11/255) : Color(red: 11/255, green: 11/255, blue: 11/255).opacity(0.08), lineWidth: 1)
                            )
                            .shadow(color: confirmPasswordFieldFocused ? Color(red: 11/255, green: 11/255, blue: 11/255).opacity(0.05) : Color(red: 11/255, green: 11/255, blue: 11/255).opacity(0.06), radius: confirmPasswordFieldFocused ? 4 : 1, x: 0, y: confirmPasswordFieldFocused ? 0 : 1)
                        }

                        // MFA code field
                        if authManager.isMFARequired && !isSignupMode {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Two-Factor Authentication")
                                    .font(.geist(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                                    .padding(.bottom, 8)

                                TextField("6-digit code", text: $otpCode)
                                    .keyboardType(.numberPad)
                                    .textContentType(.oneTimeCode)
                                    .font(.geist(size: 17))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 16)
                            }
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(red: 229/255, green: 229/255, blue: 229/255), lineWidth: 1)
                                    .padding(1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)

                    // Forgot password link (only for sign in)
                    if !isSignupMode {
                        HStack {
                            Button(action: {
                                // TODO: Handle forgot password
                            }) {
                                Text("Forgot password?")
                                    .font(.geist(size: 15))
                                    .foregroundColor(.black)
                                    .underline()
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                    
                    // Error message
                    if let error = authManager.error {
                        HStack {
                            Text(error)
                                .font(.geist(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    
                    Spacer()

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
                            }
                            Text(isSignupMode ? "Create Account" : "Sign in")
                                .font(.geist(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isFormValid ? Color.black : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(28)
                    }
                    .disabled(!isFormValid || authManager.isLoading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)

                    // Toggle between login and signup
                    if isSignupMode {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSignupMode.toggle()
                                clearForm()
                            }
                        }) {
                            HStack {
                                Text("Already have an account?")
                                    .font(.geist(size: 15))
                                    .foregroundColor(.secondary)
                                Text("Sign In")
                                    .font(.geist(size: 15, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .accentColor(.black)
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