import FirebaseMessaging
import FirebaseAuth
import FirebaseCore
import FirebaseFunctions
import Foundation

/// Manager for device registration with Firebase on watchOS.
///
/// Handles:
/// - Registering watchOS devices for push notifications via Cloud Functions
/// - Storing FCM tokens
/// - Device heartbeats and status updates
@MainActor
@Observable
final class DeviceRegistrationManager {

  // MARK: - State

  /// Whether the device is currently registered
  var isRegistered = false

  /// Last registration error if any
  var lastError: Error?

  // MARK: - Dependencies

  private let authManager: AuthManager
  private let pushDelegate: PushNotificationDelegate
  private lazy var functions = Functions.functions()

  // MARK: - Device Info

  /// Unique identifier for this device
  var deviceId: String {
    // Use a stable identifier for watchOS
    if let existingId = UserDefaults.standard.string(forKey: "pushed_device_id") {
      return existingId
    }

    let newId = "watchos_\(UUID().uuidString)"
    UserDefaults.standard.set(newId, forKey: "pushed_device_id")
    return newId
  }

  /// Human-readable device name
  var deviceName: String {
    #if os(watchOS)
      return "Apple Watch"
    #else
      return "Unknown Device"
    #endif
  }

  // MARK: - Initialization

  init(authManager: AuthManager, pushDelegate: PushNotificationDelegate) {
    self.authManager = authManager
    self.pushDelegate = pushDelegate
  }

  // MARK: - Public Methods

  /// Register this device for push notifications.
  ///
  /// Must be called after successful authentication.
  func registerDevice() async throws {
    guard authManager.currentUserId != nil else {
      throw DeviceError.notAuthenticated
    }

    // Ensure we have a valid FCM token
    let fcmToken = try await pushDelegate.getToken()

    let deviceData: [String: Any] = [
      "deviceId": deviceId,
      "type": "watchos",
      "fcmToken": fcmToken,
      "deviceName": deviceName,
      "osVersion": getOSVersion(),
    ]

    do {
      // Call the registerDevice Cloud Function
      // Note: You must deploy a corresponding 'registerDevice' function in your Firebase project
      let result =
        try await functions
        .httpsCallable("registerDevice")
        .call(deviceData)

      if let response = result.data as? [String: Any],
        let success = response["success"] as? Bool, success
      {
        isRegistered = true
        lastError = nil
        print("Device registered successfully via Functions: \(deviceId)")
      } else {
        throw DeviceError.registrationFailed("Function returned failure")
      }
    } catch {
      lastError = error
      throw DeviceError.registrationFailed(error.localizedDescription)
    }
  }

  /// Unregister this device.
  ///
  /// Called when user signs out.
  func unregisterDevice() async throws {
    guard authManager.currentUserId != nil else {
      throw DeviceError.notAuthenticated
    }

    let data: [String: Any] = [
      "deviceId": deviceId
    ]

    do {
      _ =
        try await functions
        .httpsCallable("unregisterDevice")
        .call(data)

      isRegistered = false
      print("Device unregistered via Functions: \(deviceId)")
    } catch {
      throw DeviceError.unregistrationFailed(error.localizedDescription)
    }
  }

  /// Update the FCM token for this device.
  ///
  /// Called when FCM token is refreshed.
  func updateToken(_ newToken: String) async throws {
    guard authManager.currentUserId != nil else {
      return  // Silently fail if not authenticated
    }

    let data: [String: Any] = [
      "deviceId": deviceId,
      "fcmToken": newToken,
    ]

    do {
      _ =
        try await functions
        .httpsCallable("updateDeviceToken")
        .call(data)

      print("FCM token updated via Functions for device \(deviceId)")
    } catch {
      print("Failed to update FCM token: \(error)")
    }
  }

  /// Send a heartbeat to update lastSeen timestamp.
  func sendHeartbeat() async {
    guard authManager.currentUserId != nil, isRegistered else {
      return
    }

    let data: [String: Any] = [
      "deviceId": deviceId
    ]

    do {
      _ =
        try await functions
        .httpsCallable("deviceHeartbeat")
        .call(data)
    } catch {
      print("Failed to send heartbeat: \(error)")
    }
  }

  // MARK: - Private Methods

  private func getOSVersion() -> String {
    #if os(watchOS)
      return
        "watchOS \(ProcessInfo.processInfo.operatingSystemVersion.majorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion)"
    #else
      return "Unknown"
    #endif
  }
}

// MARK: - Errors

enum DeviceError: LocalizedError {
  case notAuthenticated
  case registrationFailed(String)
  case unregistrationFailed(String)
  case tokenNotAvailable

  var errorDescription: String? {
    switch self {
    case .notAuthenticated:
      "User must be authenticated"
    case .registrationFailed(let reason):
      "Device registration failed: \(reason)"
    case .unregistrationFailed(let reason):
      "Device unregistration failed: \(reason)"
    case .tokenNotAvailable:
      "FCM token not available"
    }
  }
}

