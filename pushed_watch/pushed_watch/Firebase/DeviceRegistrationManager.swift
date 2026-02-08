import FirebaseAuth
import FirebaseCore
import FirebaseFunctions
import FirebaseMessaging
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

  /// Last registration error if any
  var lastError: Error?

  // MARK: - Dependencies

  private let authManager: AuthManager
  private let pushDelegate: PushNotificationDelegate

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
  /// This will create or update the device registration in Firestore via Cloud Function.
  func registerDevice() async throws {
    guard let userId = authManager.currentUserId else {
      throw DeviceError.notAuthenticated
    }

    // Ensure we have a valid FCM token
    let fcmToken = try await pushDelegate.getToken()

    // Include userId explicitly in the request data
    // This ensures the Cloud Function knows which user to register the device for,
    // even if request.auth is not properly populated on watchOS
    let deviceData: [String: Any] = [
      "userId": userId,
      "deviceId": deviceId,
      "type": "watchos",
      "fcmToken": fcmToken,
      "deviceName": deviceName,
      "osVersion": getOSVersion(),
      "appVersion": getAppVersion(),
    ]

    do {
      // Call the registerDevice Cloud Function
      let functions = Functions.functions(region: "us-central1")
      let result = try await functions.httpsCallable("registerDevice").call(deviceData)

      if let response = result.data as? [String: Any],
        let success = response["success"] as? Bool, success
      {
        lastError = nil
        print("✅ Device registered/updated successfully via Cloud Functions: \(deviceId)")
      } else {
        print("❌ Device registration function returned failure response: \(result.data ?? "nil")")
        throw DeviceError.registrationFailed("Function returned failure")
      }
    } catch {
      print("❌ Device registration failed with error: \(error)")
      lastError = error
      throw DeviceError.registrationFailed(error.localizedDescription)
    }
  }

  /// Unregister this device.
  ///
  /// Called when user signs out.
  func unregisterDevice() async throws {
    guard let userId = authManager.currentUserId else {
      throw DeviceError.notAuthenticated
    }

    let data: [String: Any] = [
      "userId": userId,
      "deviceId": deviceId,
    ]

    do {
      _ =
        try await Functions.functions(region: "us-central1")
        .httpsCallable("unregisterDevice")
        .call(data)

      print("Device unregistered via Functions: \(deviceId)")
    } catch {
      throw DeviceError.unregistrationFailed(error.localizedDescription)
    }
  }

  /// Update the FCM token for this device.
  ///
  /// Called when FCM token is refreshed.
  func updateToken(_ newToken: String) async throws {
    guard let userId = authManager.currentUserId else {
      return  // Silently fail if not authenticated
    }

    let data: [String: Any] = [
      "userId": userId,
      "deviceId": deviceId,
      "fcmToken": newToken,
    ]

    do {
      _ =
        try await Functions.functions(region: "us-central1")
        .httpsCallable("updateDeviceToken")
        .call(data)

      print("FCM token updated via Functions for device \(deviceId)")
    } catch {
      print("Failed to update FCM token: \(error)")
    }
  }

  /// Send a heartbeat to update lastSeen timestamp.
  func sendHeartbeat() async {
    guard let userId = authManager.currentUserId else {
      return
    }

    let data: [String: Any] = [
      "userId": userId,
      "deviceId": deviceId,
    ]

    do {
      _ =
        try await Functions.functions(region: "us-central1")
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

  private func getAppVersion() -> String {
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
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
