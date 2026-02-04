import FirebaseAuth
import Foundation

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
  var authState: AuthState = .loading

  /// Current user ID if authenticated
  var currentUserId: String? {
    Auth.auth().currentUser?.uid
  }

  /// Whether user is currently authenticated
  var isAuthenticated: Bool {
    Auth.auth().currentUser != nil
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
    setupAuthStateListener()
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
    do {
      let result = try await Auth.auth().signIn(withEmail: email, password: password)
      return result.user.uid
    } catch {
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
    do {
      let result = try await Auth.auth().createUser(withEmail: email, password: password)
      return result.user.uid
    } catch {
      throw AuthError.accountCreationFailed(error.localizedDescription)
    }
  }

  /// Sign out the current user.
  func signOut() throws {
    do {
      try Auth.auth().signOut()
    } catch {
      throw AuthError.signOutFailed(error.localizedDescription)
    }
  }

  /// Send password reset email.
  ///
  /// - Parameter email: User's email address
  func sendPasswordReset(to email: String) async throws {
    do {
      try await Auth.auth().sendPasswordReset(withEmail: email)
    } catch {
      throw AuthError.passwordResetFailed(error.localizedDescription)
    }
  }

  /// Reload current user's profile.
  func reloadUser() async throws {
    guard let user = Auth.auth().currentUser else {
      throw AuthError.notAuthenticated
    }

    try await user.reload()
    updateAuthState()
  }

  // MARK: - Private Methods

  private func setupAuthStateListener() {
    authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      self?.handleAuthStateChange(user: user)
    }
  }

  private func handleAuthStateChange(user: User?) {
    if let user {
      authState = .authenticated(
        userId: user.uid,
        email: user.email,
        displayName: user.displayName
      )
    } else {
      authState = .unauthenticated
    }
  }

  private func updateAuthState() {
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
