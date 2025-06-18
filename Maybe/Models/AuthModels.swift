import Foundation

// MARK: - Device Information
struct DeviceInfo: Codable {
    let device_id: String
    let device_name: String
    let device_type: String
    let os_version: String
    let app_version: String
}

// MARK: - Authentication Tokens
struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let createdAt: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case createdAt = "created_at"
    }
    
    var expiresAt: Date {
        Date(timeIntervalSince1970: TimeInterval(createdAt + expiresIn))
    }
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
    
    // Check if token will expire within the next 5 minutes
    var needsRefresh: Bool {
        let fiveMinutesFromNow = Date().addingTimeInterval(5 * 60)
        return fiveMinutesFromNow >= expiresAt
    }
}

// MARK: - User Model
struct User: Codable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

// MARK: - Authentication Responses
struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let createdAt: Int
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case createdAt = "created_at"
        case user
    }
    
    var tokens: AuthTokens {
        AuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: tokenType,
            expiresIn: expiresIn,
            createdAt: createdAt
        )
    }
}

// MARK: - Request Models
struct SignupRequest: Codable {
    let user: SignupUser
    let device: DeviceInfo
    
    struct SignupUser: Codable {
        let email: String
        let password: String
        let firstName: String
        let lastName: String
        
        enum CodingKeys: String, CodingKey {
            case email
            case password
            case firstName = "first_name"
            case lastName = "last_name"
        }
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
    let device: DeviceInfo
    let otpCode: String?
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
        case device
        case otpCode = "otp_code"
    }
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
    let device: DeviceInfo
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
        case device
    }
}

// MARK: - Error Responses
struct AuthErrorResponse: Codable {
    let error: String?
    let errors: [String]?
    let mfaRequired: Bool?
    
    enum CodingKeys: String, CodingKey {
        case error
        case errors
        case mfaRequired = "mfa_required"
    }
}