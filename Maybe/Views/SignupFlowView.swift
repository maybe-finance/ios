//
//  SignupFlowView.swift
//  Maybe
//
//  Created on 7/2/25.
//

import SwiftUI
import UserNotifications

struct SignupFlowView: View {
    @EnvironmentObject var authManager: MaybeAuthManager
    @Environment(\.dismiss) private var dismiss
    
    // Form data
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedMoneyStatements: Set<String> = []
    @State private var country = "United States"
    @State private var preferredCurrency = "USD"
    @State private var notificationsEnabled = false
    @State private var userMaybe = ""
    
    // UI State
    @State private var currentStep = 1
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?
    @State private var passwordStrength: PasswordStrength = .weak
    
    private let totalSteps = 8
    
    enum Field: Hashable {
        case firstName, lastName, email, password, maybe
    }
    
    enum PasswordStrength {
        case weak, fair, good, strong
        
        var color: Color {
            switch self {
            case .weak: return .red
            case .fair: return .orange
            case .good: return .yellow
            case .strong: return .green
            }
        }
        
        var text: String {
            switch self {
            case .weak: return "Weak"
            case .fair: return "Fair"
            case .good: return "Good"
            case .strong: return "Strong"
            }
        }
    }
    
    let moneyStatements = [
        "I want to save more money",
        "I need to pay off debt",
        "I'm planning for retirement",
        "I want to invest wisely",
        "I need to budget better",
        "I'm saving for a big purchase",
        "I want financial peace of mind"
    ]
    
    let countries = ["United States", "Canada", "United Kingdom", "Australia", "Germany", "France", "Japan", "Other"]
    let currencies = ["USD", "CAD", "GBP", "EUR", "AUD", "JPY"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.96, blue: 0.96)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Navigation bar with buttons
                    HStack {
                        Button(action: handleBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 32, height: 32)
                                .background(Color(red: 229/255, green: 229/255, blue: 229/255))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 32, height: 32)
                                .background(Color(red: 229/255, green: 229/255, blue: 229/255))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    // Progress Bar
                    progressBar
                        .padding(.horizontal, 24)
                    
                    ScrollView {
                        VStack(spacing: 32) {
                            // Step Title
                            HStack {
                                Text(getStepTitle())
                                    .font(.custom("Geist-Medium", size: 28))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            .padding(.top, 40)
                            .padding(.horizontal, 24)
                            
                            // Step Content
                            getStepContent()
                                .padding(.horizontal, 24)
                            
                            // Error message
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .font(.custom("Geist-Regular", size: 14))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 8)
                            }
                            
                            Spacer(minLength: 80)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    
                    // Bottom Buttons
                    bottomButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 34)
                        .background(
                            Color(red: 0.96, green: 0.96, blue: 0.96)
                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                        )
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black)
                    .frame(width: geometry.size.width * (Double(currentStep) / Double(totalSteps)), height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 8)
    }
    
    // MARK: - Step Content
    private func getStepContent() -> AnyView {
        switch currentStep {
        case 1:
            return AnyView(nameStep)
        case 2:
            return AnyView(emailStep)
        case 3:
            return AnyView(passwordStep)
        case 4:
            return AnyView(moneyStep)
        case 5:
            return AnyView(locationStep)
        case 6:
            return AnyView(notificationsStep)
        case 7:
            return AnyView(maybeStep)
        case 8:
            return AnyView(trialStep)
        default:
            return AnyView(EmptyView())
        }
    }
    
    private func getStepTitle() -> String {
        switch currentStep {
        case 1:
            return "Hey there, what's your name?"
        case 2:
            return "Nice to meet you, \(firstName.isEmpty ? "there" : firstName)! What's your email?"
        case 3:
            return "Create a password you won't forget"
        case 4:
            return "Where are you at with your money?"
        case 5:
            return "Let's get things just right for you"
        case 6:
            return "Turn on notifications?"
        case 7:
            return "One more thing, what's your maybe?"
        case 8:
            return "Claim your free trial"
        default:
            return ""
        }
    }
    
    // MARK: - Step 1: Name
    private var nameStep: some View {
        VStack(spacing: 16) {
            // First Name Field
            VStack(alignment: .leading, spacing: 0) {
                Text("First Name")
                    .font(.custom("Geist-Medium", size: 13))
                    .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                TextField("Enter first name", text: $firstName)
                    .textContentType(.givenName)
                    .font(.custom("Geist-Regular", size: 17))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .focused($focusedField, equals: .firstName)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .lastName
                    }
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedField == .firstName ? Color.black : Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            // Last Name Field
            VStack(alignment: .leading, spacing: 0) {
                Text("Last Name")
                    .font(.custom("Geist-Medium", size: 13))
                    .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                TextField("Enter last name", text: $lastName)
                    .textContentType(.familyName)
                    .font(.custom("Geist-Regular", size: 17))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .focused($focusedField, equals: .lastName)
                    .submitLabel(.done)
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedField == .lastName ? Color.black : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .onAppear {
            focusedField = .firstName
        }
    }
    
    // MARK: - Step 2: Email
    private var emailStep: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Email")
                    .font(.custom("Geist-Medium", size: 13))
                    .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                TextField("Enter your email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .font(.custom("Geist-Regular", size: 17))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.done)
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedField == .email ? Color.black : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .onAppear {
            focusedField = .email
        }
    }
    
    // MARK: - Step 3: Password
    private var passwordStep: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Password")
                    .font(.custom("Geist-Medium", size: 13))
                    .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                SecureField("Create a password", text: $password)
                    .textContentType(.newPassword)
                    .font(.custom("Geist-Regular", size: 17))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.done)
                    .onChange(of: password) { _ in
                        passwordStrength = calculatePasswordStrength(password)
                    }
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedField == .password ? Color.black : Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            // Password Strength Indicator
            HStack(spacing: 8) {
                Text("Strength:")
                    .font(.custom("Geist-Regular", size: 14))
                    .foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    ForEach(0..<4) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index < strengthLevel(passwordStrength) ? passwordStrength.color : Color.gray.opacity(0.2))
                            .frame(width: 40, height: 4)
                    }
                }
                
                Text(passwordStrength.text)
                    .font(.custom("Geist-Regular", size: 14))
                    .foregroundColor(passwordStrength.color)
                
                Spacer()
            }
        }
        .onAppear {
            focusedField = .password
        }
    }
    
    // MARK: - Step 4: Money Statements
    private var moneyStep: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Select all that apply:")
                    .font(.custom("Geist-Regular", size: 16))
                    .foregroundColor(.gray)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(moneyStatements, id: \.self) { statement in
                    Button(action: {
                        if selectedMoneyStatements.contains(statement) {
                            selectedMoneyStatements.remove(statement)
                        } else {
                            selectedMoneyStatements.insert(statement)
                        }
                    }) {
                        HStack {
                            Text(statement)
                                .font(.custom("Geist-Regular", size: 16))
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Image(systemName: selectedMoneyStatements.contains(statement) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedMoneyStatements.contains(statement) ? .green : .gray)
                                .font(.system(size: 22))
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedMoneyStatements.contains(statement) ? Color.green.opacity(0.1) : Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedMoneyStatements.contains(statement) ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Step 5: Location
    private var locationStep: some View {
        VStack(spacing: 16) {
            // Country Field
            VStack(alignment: .leading, spacing: 0) {
                Text("Country")
                    .font(.custom("Geist-Medium", size: 13))
                    .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                Menu {
                    ForEach(countries, id: \.self) { country in
                        Button(action: { self.country = country }) {
                            Text(country)
                        }
                    }
                } label: {
                    HStack {
                        Text(country)
                            .font(.custom("Geist-Regular", size: 17))
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            // Currency Field
            VStack(alignment: .leading, spacing: 0) {
                Text("Preferred Currency")
                    .font(.custom("Geist-Medium", size: 13))
                    .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                Menu {
                    ForEach(currencies, id: \.self) { currency in
                        Button(action: { self.preferredCurrency = currency }) {
                            Text(currency)
                        }
                    }
                } label: {
                    HStack {
                        Text(preferredCurrency)
                            .font(.custom("Geist-Regular", size: 17))
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Step 6: Notifications
    private var notificationsStep: some View {
        VStack(spacing: 32) {
            // Notification Icon/Image
            Image(systemName: "bell.badge")
                .font(.system(size: 80))
                .foregroundColor(.black)
                .padding(.top, 40)
            
            VStack(spacing: 16) {
                Text("Stay on top of your finances")
                    .font(.custom("Geist-Medium", size: 20))
                    .foregroundColor(.black)
                
                Text("Get helpful reminders about bills, spending insights, and progress toward your goals.")
                    .font(.custom("Geist-Regular", size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Step 7: Maybe
    private var maybeStep: some View {
        VStack(spacing: 20) {
            HStack {
                Text("What's something you're hoping to achieve with Maybe? A dream, a goal, or just a little more peace of mind?")
                    .font(.custom("Geist-Regular", size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Your Maybe")
                    .font(.custom("Geist-Medium", size: 13))
                    .foregroundColor(Color(red: 115/255, green: 115/255, blue: 115/255))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $userMaybe)
                        .font(.custom("Geist-Regular", size: 17))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .focused($focusedField, equals: .maybe)
                        .frame(minHeight: 100)
                    
                    if userMaybe.isEmpty {
                        Text("Tell us your maybe...")
                            .font(.custom("Geist-Regular", size: 17))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.bottom, 8)
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedField == .maybe ? Color.black : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .onAppear {
            focusedField = .maybe
        }
    }
    
    // MARK: - Step 8: Free Trial
    private var trialStep: some View {
        VStack(spacing: 32) {
            // Pricing Graphic
            VStack(spacing: 24) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.black)
                
                VStack(spacing: 16) {
                    Text("Start your 14-day free trial")
                        .font(.custom("Geist-Semibold", size: 24))
                        .foregroundColor(.black)
                    
                    VStack(spacing: 8) {
                        Text("Then $14.99/month")
                            .font(.custom("Geist-Medium", size: 18))
                            .foregroundColor(.black)
                        
                        Text("Cancel anytime")
                            .font(.custom("Geist-Regular", size: 16))
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("All premium features")
                            .font(.custom("Geist-Regular", size: 16))
                            .foregroundColor(.black)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Unlimited accounts")
                            .font(.custom("Geist-Regular", size: 16))
                            .foregroundColor(.black)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Advanced insights")
                            .font(.custom("Geist-Regular", size: 16))
                            .foregroundColor(.black)
                    }
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Bottom Buttons
    private var bottomButtons: some View {
        Group {
            if currentStep == 6 {
                // Notifications step has different buttons
                VStack(spacing: 12) {
                    Button(action: {
                        requestNotificationPermission()
                    }) {
                        Text("Allow notifications")
                            .font(.custom("Geist-Semibold", size: 17))
                    }
                    .buttonStyle(GlossyButtonStyle())
                    
                    Button(action: {
                        notificationsEnabled = false
                        nextStep()
                    }) {
                        Text("Maybe later")
                            .font(.custom("Geist-Medium", size: 17))
                            .foregroundColor(.gray)
                    }
                }
            } else if currentStep == 8 {
                // Trial step has single button
                Button(action: handleSignup) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Start free trial")
                                .font(.custom("Geist-Semibold", size: 17))
                        }
                    }
                }
                .buttonStyle(GlossyButtonStyle())
                .disabled(isLoading)
            } else {
                // Regular continue button
                Button(action: nextStep) {
                    Text("Continue")
                        .font(.custom("Geist-Semibold", size: 17))
                }
                .buttonStyle(GlossyButtonStyle())
                .disabled(!isStepValid())
                .opacity(isStepValid() ? 1 : 0.5)
            }
        }
    }
    
    // MARK: - Navigation
    private func nextStep() {
        withAnimation {
            if currentStep < totalSteps {
                currentStep += 1
            }
        }
    }
    
    private func handleBack() {
        if currentStep > 1 {
            withAnimation {
                currentStep -= 1
            }
        } else {
            dismiss()
        }
    }
    
    // MARK: - Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                self.nextStep()
            }
        }
    }
    
    // MARK: - Validation
    private func isStepValid() -> Bool {
        switch currentStep {
        case 1:
            return !firstName.isEmpty && !lastName.isEmpty
        case 2:
            return isValidEmail(email)
        case 3:
            return isValidPassword()
        case 4:
            return !selectedMoneyStatements.isEmpty
        case 5:
            return true // Country and currency have defaults
        case 6:
            return true // Notifications step always valid
        case 7:
            return !userMaybe.isEmpty
        case 8:
            return true // Trial step is always valid
        default:
            return false
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPassword() -> Bool {
        return password.count >= 8
    }
    
    private func calculatePasswordStrength(_ password: String) -> PasswordStrength {
        var strength = 0
        
        if password.count >= 8 { strength += 1 }
        if password.count >= 12 { strength += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { strength += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { strength += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { strength += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { strength += 1 }
        
        switch strength {
        case 0...2: return .weak
        case 3...4: return .fair
        case 5: return .good
        default: return .strong
        }
    }
    
    private func strengthLevel(_ strength: PasswordStrength) -> Int {
        switch strength {
        case .weak: return 1
        case .fair: return 2
        case .good: return 3
        case .strong: return 4
        }
    }
    
    // MARK: - Signup
    private func handleSignup() {
        isLoading = true
        errorMessage = nil
        
        Task {
            await authManager.signup(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )
            
            await MainActor.run {
                isLoading = false
                
                // Check if signup was successful
                if authManager.isAuthenticated {
                    // Store additional user preferences if needed
                    // For now, just dismiss to go back to ContentView
                    dismiss()
                } else if let error = authManager.error {
                    errorMessage = error
                }
            }
        }
    }
}

