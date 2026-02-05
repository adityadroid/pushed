import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFunctions

/// Service for synchronizing notifications with the Android companion app.
///
/// Uses WatchConnectivity for communication when an iPhone is present,
/// or direct Bluetooth/network communication for standalone mode.
@MainActor
@Observable
final class NotificationSyncService {
    
    // MARK: - State
    
    /// Whether sync is currently in progress
    var isSyncing = false
    
    /// Last successful sync timestamp
    var lastSyncTime: Date?
    
  /// Whether the Android device is reachable
  var isReachable = false

  // MARK: - Dependencies

  private let functions: Functions?
  private let deviceIdProvider: (() -> String?)?
  private nonisolated(unsafe) var authStateListener: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initialization
    
  init(
    functions: Functions? = nil,
    deviceIdProvider: (() -> String?)? = nil
  ) {
    if let functions {
      self.functions = functions
    } else if FirebaseApp.app() != nil {
      self.functions = Functions.functions()
    } else {
      self.functions = nil
    }
    self.deviceIdProvider = deviceIdProvider
    setupConnectivity()
  }

  deinit {
    if let listener = authStateListener {
      Auth.auth().removeStateDidChangeListener(listener)
    }
  }
    
    // MARK: - Public Methods
    
    /// Request a full sync of notifications from Android
  func requestSync() async throws {
    try ensureAuthenticated()
    try ensureBackendAvailable()

    isSyncing = true
    defer { isSyncing = false }

    // Since delivery is push-based, we treat refresh as a heartbeat.
    if let deviceId = deviceIdProvider?(), let functions {
      _ = try await functions.httpsCallable("deviceHeartbeat").call(["deviceId": deviceId])
    }
    lastSyncTime = Date()
  }
    
    /// Send a dismissal event back to Android
  func sendDismissal(for notificationId: UUID) async throws {
    try ensureAuthenticated()
    try ensureBackendAvailable()

    let payload: [String: Any] = [
      "notificationId": notificationId.uuidString,
      "timestamp": ISO8601DateFormatter().string(from: Date())
    ]

    if let functions {
      _ = try await functions.httpsCallable("dismissNotification").call(payload)
    }
  }
    
    /// Send an action execution request to Android
  func sendAction(_ action: NotificationAction, for notificationId: UUID) async throws {
    try ensureAuthenticated()
    try ensureBackendAvailable()

    let payload: [String: Any] = [
      "notificationId": notificationId.uuidString,
      "actionId": action.id,
      "actionLabel": action.label,
      "timestamp": ISO8601DateFormatter().string(from: Date())
    ]

    if let functions {
      _ = try await functions.httpsCallable("handleNotificationAction").call(payload)
    }
  }
    
    // MARK: - Private Methods
    
  private func setupConnectivity() {
    guard FirebaseApp.app() != nil else {
      isReachable = false
      return
    }

    authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      Task { @MainActor in
        self?.isReachable = (user != nil)
      }
    }

    isReachable = Auth.auth().currentUser != nil
  }

  private func ensureAuthenticated() throws {
    guard FirebaseApp.app() != nil else {
      throw SyncError.backendUnavailable
    }
    guard Auth.auth().currentUser != nil else {
      throw SyncError.notAuthenticated
    }
  }

  private func ensureBackendAvailable() throws {
    guard functions != nil else {
      throw SyncError.backendUnavailable
    }
  }
    
    /// Handle incoming notification data from Android
    func handleIncomingNotification(_ data: Data) async throws -> PushedNotification {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let notification = try decoder.decode(PushedNotification.self, from: data)
        
        // Validate schema version
        guard SchemaVersion.isCompatible(notification.schemaVersion) else {
            throw SyncError.incompatibleSchema(notification.schemaVersion)
        }
        
        return notification
    }
}

// MARK: - Errors

enum SyncError: LocalizedError {
  case notAuthenticated
  case backendUnavailable
  case notReachable
  case incompatibleSchema(String)
  case timeout
  case unknown(Error)

  var errorDescription: String? {
    switch self {
    case .notAuthenticated:
      "User must be authenticated to sync"
    case .backendUnavailable:
      "Sync backend is not configured"
    case .notReachable:
      "Android device is not reachable"
    case .incompatibleSchema(let version):
      "Incompatible notification format (version \(version))"
    case .timeout:
      "Connection timed out"
    case .unknown(let error):
      "Sync failed: \(error.localizedDescription)"
    }
  }
}
