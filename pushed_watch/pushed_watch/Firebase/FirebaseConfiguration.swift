import Foundation
import FirebaseCore

/// Firebase configuration and initialization for watchOS.
///
/// **Signing Identity**: adityagurjar.it18@gmail.com
/// **Bundle Identifier**: Must match Firebase project configuration
///
/// This class handles:
/// - Firebase SDK initialization
/// - Configuration validation
/// - APNs setup for FCM
@MainActor
final class FirebaseConfiguration {
    
    static let shared = FirebaseConfiguration()
    
    /// Whether Firebase has been configured
    private(set) var isConfigured = false
    
    private init() {}
    
    /// Configure Firebase SDK.
    ///
    /// Must be called early in app lifecycle, typically in App init.
    func configure() {
        guard !isConfigured else {
            print("Firebase already configured")
            return
        }
        
        // Configure Firebase with default options
        // This uses GoogleService-Info.plist
        FirebaseApp.configure()
        
        isConfigured = true
        print("Firebase configured successfully")
        
        // Log configuration for debugging
        if let app = FirebaseApp.app() {
            print("Firebase App Name: \(app.name)")
            print("Firebase Project ID: \(app.options.projectID ?? "unknown")")
        }
    }
    
    /// Validate Firebase configuration.
    func validateConfiguration() throws {
        guard isConfigured else {
            throw ConfigurationError.notConfigured
        }
        
        guard let app = FirebaseApp.app() else {
            throw ConfigurationError.invalidConfiguration
        }
        
        guard app.options.projectID != nil else {
            throw ConfigurationError.missingProjectId
        }
        
        guard app.options.googleAppID != nil else {
            throw ConfigurationError.missingAppId
        }
    }
}

// MARK: - Errors

enum ConfigurationError: LocalizedError {
    case notConfigured
    case invalidConfiguration
    case missingProjectId
    case missingAppId
    case missingGoogleServiceInfo
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Firebase has not been configured"
        case .invalidConfiguration:
            "Firebase configuration is invalid"
        case .missingProjectId:
            "Firebase project ID is missing"
        case .missingAppId:
            "Firebase app ID is missing"
        case .missingGoogleServiceInfo:
            "GoogleService-Info.plist is missing"
        }
    }
}
