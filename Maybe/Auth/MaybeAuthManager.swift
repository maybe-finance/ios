import Foundation
import Security
import Combine

@MainActor
class MaybeAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentUser: User?
    @Published var isMFARequired = false
    
    private var cancellables = Set<AnyCancellable>()
    private var authTokens: AuthTokens?
    private let keychainService = "MaybeApp"
    private let keychainAccount = "auth_tokens"
    private let userDefaultsKey = "MaybeApp.CurrentUser"
    
    // API client will be injected from outside
    weak var apiClient: MaybeAPIClient?
    
    init() {
        // Check if we need to clear old OAuth tokens
        let hasCleared = UserDefaults.standard.bool(forKey: "MaybeApp.HasClearedOldTokens")
        if !hasCleared {
            print("🧹 Clearing all old authentication data...")
            clearAllAuthData()
            UserDefaults.standard.set(true, forKey: "MaybeApp.HasClearedOldTokens")
        }
        
        loadStoredData()
    }
    
    // MARK: - Public Methods
    
    func signup(email: String, password: String, firstName: String, lastName: String) async {
        isLoading = true
        error = nil
        
        let signupRequest = SignupRequest(
            user: SignupRequest.SignupUser(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            ),
            device: DeviceInfoManager.shared.currentDeviceInfo
        )
        
        do {
            guard let apiClient = apiClient else {
                error = "API client not configured"
                isLoading = false
                return
            }
            let response = try await apiClient.signup(request: signupRequest)
            await handleAuthSuccess(response: response)
        } catch {
            await handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func login(email: String, password: String, otpCode: String? = nil) async {
        isLoading = true
        error = nil
        isMFARequired = false
        
        let loginRequest = LoginRequest(
            email: email,
            password: password,
            device: DeviceInfoManager.shared.currentDeviceInfo,
            otpCode: otpCode
        )
        
        do {
            guard let apiClient = apiClient else {
                error = "API client not configured"
                isLoading = false
                return
            }
            let response = try await apiClient.login(request: loginRequest)
            await handleAuthSuccess(response: response)
        } catch {
            await handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func refreshTokenIfNeeded() async {
        guard let tokens = authTokens else { return }
        
        if tokens.needsRefresh {
            await refreshToken()
        }
    }
    
    func logout() {
        clearStoredData()
        isAuthenticated = false
        currentUser = nil
        authTokens = nil
    }
    
    func getAccessToken() -> String? {
        return authTokens?.accessToken
    }
    
    // MARK: - Private Methods
    
    private func refreshToken() async {
        guard let refreshToken = authTokens?.refreshToken else {
            logout()
            return
        }
        
        let refreshRequest = RefreshTokenRequest(
            refreshToken: refreshToken,
            device: DeviceInfoManager.shared.currentDeviceInfo
        )
        
        do {
            guard let apiClient = apiClient else {
                logout()
                return
            }
            let tokens = try await apiClient.refreshToken(request: refreshRequest)
            self.authTokens = tokens
            storeTokensSecurely(tokens)
            updateAPIClientAuth()
        } catch {
            // If refresh fails, log the user out
            logout()
        }
    }
    
    private func handleAuthSuccess(response: AuthResponse) async {
        authTokens = response.tokens
        currentUser = response.user
        isAuthenticated = true
        isMFARequired = false
        
        // Debug token dates
        print("🎫 Token received:")
        print("   Created at: \(response.tokens.createdAt) (\(Date(timeIntervalSince1970: TimeInterval(response.tokens.createdAt))))")
        print("   Expires in: \(response.tokens.expiresIn) seconds")
        print("   Expires at: \(response.tokens.expiresAt)")
        print("   Is expired: \(response.tokens.isExpired)")
        print("   Current date: \(Date())")
        
        // Store data securely
        storeTokensSecurely(response.tokens)
        storeUserData(response.user)
        
        // Update API client with new auth
        updateAPIClientAuth()
    }
    
    private func handleAuthError(_ error: Error) async {
        if let apiError = error as? APIError {
            switch apiError {
            case .mfaRequired:
                isMFARequired = true
                self.error = nil // Don't show error for MFA requirement
            case .validationErrors(let errors):
                self.error = errors.joined(separator: "\n")
            default:
                self.error = apiError.localizedDescription
            }
        } else {
            self.error = error.localizedDescription
        }
    }
    
    private func updateAPIClientAuth() {
        // API client will be updated externally
    }
    
    // MARK: - Keychain Storage
    
    private func storeTokensSecurely(_ tokens: AuthTokens) {
        do {
            let data = try JSONEncoder().encode(tokens)
            
            // Delete any existing item
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: keychainAccount
            ]
            SecItemDelete(deleteQuery as CFDictionary)
            
            // Add new item
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: keychainAccount,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            let status = SecItemAdd(addQuery as CFDictionary, nil)
            if status != errSecSuccess {
                print("Error storing tokens: \(status)")
            }
        } catch {
            print("Error encoding tokens: \(error)")
        }
    }
    
    private func getStoredTokens() -> AuthTokens? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(AuthTokens.self, from: data)
        } catch {
            print("Error decoding tokens: \(error)")
            return nil
        }
    }
    
    private func clearStoredTokens() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - User Data Storage
    
    private func storeUserData(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func getStoredUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }
    
    private func clearStoredUser() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // MARK: - Data Loading
    
    private func clearAllAuthData() {
        // Clear ALL keychain items for this app
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        
        for itemClass in secItemClasses {
            let spec: [String: Any] = [
                kSecClass as String: itemClass,
                kSecAttrService as String: "MaybeApp"
            ]
            SecItemDelete(spec as CFDictionary)
        }
        
        // Also clear with different account names that might have been used
        let accountNames = ["oauth_tokens", "auth_tokens", "tokens"]
        for account in accountNames {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account
            ]
            SecItemDelete(query as CFDictionary)
        }
        
        // Clear user defaults
        clearStoredUser()
    }
    
    private func loadStoredData() {
        if let tokens = getStoredTokens() {
            print("🔑 Found stored tokens, checking validity...")
            print("   Token created at: \(Date(timeIntervalSince1970: TimeInterval(tokens.createdAt)))")
            print("   Token expires at: \(tokens.expiresAt)")
            print("   Is expired: \(tokens.isExpired)")
            
            if !tokens.isExpired {
                self.authTokens = tokens
                self.currentUser = getStoredUser()
                self.isAuthenticated = true
                print("✅ Loaded valid stored tokens")
                
                // Check if we need to refresh the token
                if tokens.needsRefresh {
                    print("🔄 Token needs refresh soon")
                    Task {
                        await refreshToken()
                    }
                }
            } else {
                print("❌ Stored tokens are expired, clearing...")
                clearStoredData()
            }
        } else {
            print("📭 No stored tokens found")
        }
    }
    
    private func clearStoredData() {
        clearStoredTokens()
        clearStoredUser()
    }
    
    // MARK: - Password Validation
    
    static func validatePassword(_ password: String) -> [String] {
        var errors: [String] = []
        
        if password.count < 8 {
            errors.append("Password must be at least 8 characters")
        }
        
        if !password.contains(where: { $0.isUppercase }) {
            errors.append("Password must contain at least one uppercase letter")
        }
        
        if !password.contains(where: { $0.isLowercase }) {
            errors.append("Password must contain at least one lowercase letter")
        }
        
        if !password.contains(where: { $0.isNumber }) {
            errors.append("Password must contain at least one number")
        }
        
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*(),.?\":{}|<>")
        if password.rangeOfCharacter(from: specialCharacters) == nil {
            errors.append("Password must contain at least one special character")
        }
        
        return errors
    }
}