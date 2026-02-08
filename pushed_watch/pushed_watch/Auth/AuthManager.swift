import FirebaseAuth
import Foundation
import os.log

/// Logger for authentication
private let logger = Logger(subsystem: "com.pushed.watch", category: "Auth")

/// Manager for Firebase Authentication on watchOS.
///
/// Provides unified authentication across the Pushed system, ensuring
/// the same UID is used on both Android sender devices and watchOS receivers.
///
/// **Important**: Signing identity must be `adityagurjar.it18@gmail.com`.
/// Do NOT use `a.gurjar@scbank.com.eg`.
@MainActor
@Observable
final class AuthManager {

  // MARK: - State

  /// Current authentication state
  var authState: AuthState = .loading {
    didSet {
      logger.info(
        "🔐 authState changed: \(String(describing: oldValue)) -> \(String(describing: self.authState))"
      )
    }
  }

  /// Current user ID if authenticated
  var currentUserId: String? {
    let uid = Auth.auth().currentUser?.uid
    logger.debug("🔐 currentUserId accessed: \(uid ?? "nil")")
    return uid
  }

  /// Whether user is currently authenticated
  var isAuthenticated: Bool {
    let authenticated = Auth.auth().currentUser != nil
    logger.debug("🔐 isAuthenticated accessed: \(authenticated)")
    return authenticated
  }

  /// Current user's email
  var userEmail: String? {
    Auth.auth().currentUser?.email
  }

  /// Current user's display name
  var displayName: String? {
    Auth.auth().currentUser?.displayName
  }

  // MARK: - Private

  private nonisolated(unsafe) var authStateListener: AuthStateDidChangeListenerHandle?

  // MARK: - Initialization

  init() {
    logger.info("🔧 AuthManager initializing...")
    logger.info(
      "🔐 Firebase Auth.auth().currentUser on init: \(Auth.auth().currentUser?.uid ?? "nil")")
    setupAuthStateListener()
    logger.info("🔧 AuthManager initialized")
  }

  deinit {
    if let listener = authStateListener {
      Auth.auth().removeStateDidChangeListener(listener)
    }
  }

  // MARK: - Public Methods

  /// Sign in with email and password.
  ///
  /// - Parameters:
  ///   - email: User's email address
  ///   - password: User's password
  /// - Returns: The authenticated user's UID
  func signIn(email: String, password: String) async throws -> String {
    logger.info("🔐 signIn() called with email: \(email)")
    do {
      let result = try await Auth.auth().signIn(withEmail: email, password: password)
      logger.info("✅ signIn() successful - uid: \(result.user.uid)")
      logger.info("   email: \(result.user.email ?? "nil")")
      logger.info("   displayName: \(result.user.displayName ?? "nil")")
      return result.user.uid
    } catch {
      logger.error("❌ signIn() failed: \(error.localizedDescription)")
      throw AuthError.signInFailed(error.localizedDescription)
    }
  }

  /// Create a new account with email and password.
  ///
  /// - Parameters:
  ///   - email: User's email address
  ///   - password: User's password
  /// - Returns: The created user's UID
  func createAccount(email: String, password: String) async throws -> String {
    logger.info("🔐 createAccount() called with email: \(email)")
    do {
      let result = try await Auth.auth().createUser(withEmail: email, password: password)
      logger.info("✅ createAccount() successful - uid: \(result.user.uid)")
      return result.user.uid
    } catch {
      logger.error("❌ createAccount() failed: \(error.localizedDescription)")
      throw AuthError.accountCreationFailed(error.localizedDescription)
    }
  }

  /// Sign out the current user.
  func signOut() throws {
    logger.info("🔐 signOut() called")
    do {
      try Auth.auth().signOut()
      logger.info("✅ signOut() successful")
    } catch {
      logger.error("❌ signOut() failed: \(error.localizedDescription)")
      throw AuthError.signOutFailed(error.localizedDescription)
    }
  }

  /// Send password reset email.
  ///
  /// - Parameter email: User's email address
  func sendPasswordReset(to email: String) async throws {
    logger.info("🔐 sendPasswordReset() called for email: \(email)")
    do {
      try await Auth.auth().sendPasswordReset(withEmail: email)
      logger.info("✅ Password reset email sent")
    } catch {
      logger.error("❌ sendPasswordReset() failed: \(error.localizedDescription)")
      throw AuthError.passwordResetFailed(error.localizedDescription)
    }
  }

  /// Reload current user's profile.
  func reloadUser() async throws {
    logger.info("🔐 reloadUser() called")
    guard let user = Auth.auth().currentUser else {
      logger.error("❌ reloadUser() failed: No current user")
      throw AuthError.notAuthenticated
    }

    try await user.reload()
    updateAuthState()
    logger.info("✅ User reloaded successfully")
  }

  // MARK: - Private Methods

  private func setupAuthStateListener() {
    logger.info("🔐 Setting up auth state listener...")
    authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      logger.info("🔔 Auth state listener fired!")
      logger.info("   user: \(user?.uid ?? "nil")")
      logger.info("   email: \(user?.email ?? "nil")")
      self?.handleAuthStateChange(user: user)
    }
    logger.info("🔐 Auth state listener set up")
  }

  private func handleAuthStateChange(user: User?) {
    logger.info("🔐 handleAuthStateChange() called")
    logger.info("   user: \(user?.uid ?? "nil")")

    if let user {
      logger.info("✅ User is authenticated")
      logger.info("   uid: \(user.uid)")
      logger.info("   email: \(user.email ?? "nil")")
      logger.info("   displayName: \(user.displayName ?? "nil")")
      authState = .authenticated(
        userId: user.uid,
        email: user.email,
        displayName: user.displayName
      )
    } else {
      logger.info("⚠️ User is NOT authenticated")
      authState = .unauthenticated
    }
  }

  private func updateAuthState() {
    logger.info("🔐 updateAuthState() called")
    handleAuthStateChange(user: Auth.auth().currentUser)
  }
}

// MARK: - Auth State

enum AuthState: Equatable {
  case loading
  case unauthenticated
  case authenticated(userId: String, email: String?, displayName: String?)

  var isAuthenticated: Bool {
    if case .authenticated = self {
      return true
    }
    return false
  }
}

// MARK: - Errors

enum AuthError: LocalizedError {
  case notAuthenticated
  case signInFailed(String)
  case accountCreationFailed(String)
  case signOutFailed(String)
  case passwordResetFailed(String)

  var errorDescription: String? {
    switch self {
    case .notAuthenticated:
      "User is not authenticated"
    case .signInFailed(let reason):
      "Sign in failed: \(reason)"
    case .accountCreationFailed(let reason):
      "Account creation failed: \(reason)"
    case .signOutFailed(let reason):
      "Sign out failed: \(reason)"
    case .passwordResetFailed(let reason):
      "Password reset failed: \(reason)"
    }
  }
}
