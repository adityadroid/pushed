import FirebaseAuth
import FirebaseCore
import FirebaseFunctions
import FirebaseMessaging
import Foundation
import os.log

/// Logger for device registration
private let logger = Logger(subsystem: "com.pushed.watch", category: "DeviceRegistration")

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

  /// Whether registration is pending (waiting for FCM token)
  private var registrationPending = false

  // MARK: - Dependencies

  private let authManager: AuthManager
  private let pushDelegate: PushNotificationDelegate

  // MARK: - Device Info

  /// Unique identifier for this device
  var deviceId: String {
    // Use a stable identifier for watchOS
    if let existingId = UserDefaults.standard.string(forKey: "pushed_device_id") {
      logger.info("📱 Using existing deviceId: \(existingId)")
      return existingId
    }

    let newId = "watchos_\(UUID().uuidString)"
    UserDefaults.standard.set(newId, forKey: "pushed_device_id")
    logger.info("📱 Generated new deviceId: \(newId)")
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
    logger.info("🔧 DeviceRegistrationManager initialized")
  }

  // MARK: - Public Methods

  /// Register this device for push notifications.
  ///
  /// Must be called after successful authentication.
  /// This will create or update the device registration in Firestore via Cloud Function.
  ///
  /// Note: If FCM token is not yet available (APNS token pending), this will
  /// gracefully handle it and registration will complete when token is ready.
  func registerDevice() async throws {
    logger.info("🚀 registerDevice() called")

    // Check auth state
    logger.info("🔐 Checking auth state...")
    logger.info("🔐 authManager.isAuthenticated = \(self.authManager.isAuthenticated)")
    logger.info("🔐 authManager.currentUserId = \(self.authManager.currentUserId ?? "nil")")

    guard let userId = authManager.currentUserId else {
      logger.error("❌ No userId available - user not authenticated")
      throw DeviceError.notAuthenticated
    }

    logger.info("✅ Got userId: \(userId)")

    // Get FCM token - handle case where APNS token isn't ready yet
    logger.info("🔑 Getting FCM token...")
    let fcmToken: String
    do {
      fcmToken = try await pushDelegate.getToken()
      logger.info("✅ Got FCM token: \(fcmToken.prefix(20))...")
    } catch {
      // Check if this is the "No APNS token" error
      let nsError = error as NSError
      if nsError.domain == "com.google.fcm" && nsError.code == 505 {
        logger.warning("⚠️ FCM token not available yet (APNS token pending)")
        logger.info(
          "⏳ Registration will be triggered when FCM token becomes available via onTokenUpdated callback"
        )
        registrationPending = true
        // Don't throw - just return. Registration will happen when onTokenUpdated fires.
        return
      }

      logger.error("❌ Failed to get FCM token: \(error.localizedDescription)")
      throw error
    }

    // Clear pending flag since we have a token
    registrationPending = false

    // Now perform the actual registration
    await performRegistration(userId: userId, fcmToken: fcmToken)
  }

  /// Performs the actual Cloud Function registration call.
  private func performRegistration(userId: String, fcmToken: String) async {
    // Build device data
    let osVersion = getOSVersion()
    let appVersion = getAppVersion()
    let currentDeviceId = deviceId
    let currentDeviceName = deviceName

    // Check if using mock token
    let isMockToken = fcmToken.hasPrefix("MOCK_FCM_TOKEN_")
    if isMockToken {
      logger.warning("⚠️⚠️⚠️ USING MOCK FCM TOKEN - Push notifications will NOT work! ⚠️⚠️⚠️")
      logger.warning("   To enable push notifications, you need a paid Apple Developer account")
    }

    logger.info("📦 Building device data...")
    logger.info("   userId: \(userId)")
    logger.info("   deviceId: \(currentDeviceId)")
    logger.info("   type: watchos")
    logger.info("   fcmToken: \(fcmToken.prefix(30))... \(isMockToken ? "(MOCK)" : "(REAL)")")
    logger.info("   deviceName: \(currentDeviceName)")
    logger.info("   osVersion: \(osVersion)")
    logger.info("   appVersion: \(appVersion)")

    let deviceData: [String: Any] = [
      "userId": userId,
      "deviceId": currentDeviceId,
      "type": "watchos",
      "fcmToken": fcmToken,
      "deviceName": currentDeviceName,
      "osVersion": osVersion,
      "appVersion": appVersion,
    ]

    do {
      logger.info("📞 Calling registerDevice Cloud Function...")
      logger.info("   Region: us-central1")

      let functions = Functions.functions(region: "us-central1")

      logger.info("   Invoking httpsCallable('registerDevice')...")
      let result = try await functions.httpsCallable("registerDevice").call(deviceData)

      logger.info("📥 Received response from Cloud Function")
      logger.info("   Response data type: \(type(of: result.data))")
      logger.info("   Response data: \(String(describing: result.data))")

      if let response = result.data as? [String: Any] {
        logger.info("   Parsed as dictionary: \(response)")
        if let success = response["success"] as? Bool {
          logger.info("   success = \(success)")
          if success {
            lastError = nil
            logger.info("✅✅✅ DEVICE REGISTRATION SUCCESSFUL! ✅✅✅")
            logger.info("   userId: \(userId)")
            logger.info("   deviceId: \(currentDeviceId)")
            print(
              "✅ Device registered/updated successfully via Cloud Functions: \(currentDeviceId)")
          } else {
            logger.error("❌ Function returned success=false")
            lastError = DeviceError.registrationFailed("Function returned failure")
          }
        } else {
          logger.error("❌ No 'success' field in response")
          lastError = DeviceError.registrationFailed("No success field in response")
        }
      } else {
        logger.error("❌ Could not parse response as dictionary")
        logger.error("   Raw data: \(String(describing: result.data))")
        lastError = DeviceError.registrationFailed("Function returned unexpected response format")
      }
    } catch {
      logger.error("❌ Cloud Function call failed!")
      logger.error("   Error type: \(type(of: error))")
      logger.error("   Error: \(error.localizedDescription)")
      logger.error("   Full error: \(String(describing: error))")

      if let functionsError = error as NSError? {
        logger.error("   NSError domain: \(functionsError.domain)")
        logger.error("   NSError code: \(functionsError.code)")
        logger.error("   NSError userInfo: \(functionsError.userInfo)")
      }

      lastError = error
      print("❌ Device registration failed with error: \(error)")
    }
  }

  /// Called when FCM token becomes available.
  /// This should be triggered from the onTokenUpdated callback.
  func onFCMTokenAvailable(_ token: String) async {
    logger.info("🔑 onFCMTokenAvailable() called with token: \(token.prefix(20))...")

    guard let userId = authManager.currentUserId else {
      logger.warning("⚠️ FCM token available but user not authenticated - skipping registration")
      return
    }

    logger.info("✅ User is authenticated, proceeding with registration")
    logger.info("   userId: \(userId)")

    await performRegistration(userId: userId, fcmToken: token)
  }

  /// Unregister this device.
  ///
  /// Called when user signs out.
  func unregisterDevice() async throws {
    logger.info("🗑️ unregisterDevice() called")

    guard let userId = authManager.currentUserId else {
      logger.error("❌ No userId available for unregister")
      throw DeviceError.notAuthenticated
    }

    logger.info("   userId: \(userId)")
    logger.info("   deviceId: \(self.deviceId)")

    let data: [String: Any] = [
      "userId": userId,
      "deviceId": deviceId,
    ]

    do {
      logger.info("📞 Calling unregisterDevice Cloud Function...")
      _ = try await Functions.functions(region: "us-central1")
        .httpsCallable("unregisterDevice")
        .call(data)

      logger.info("✅ Device unregistered successfully")
      print("Device unregistered via Functions: \(deviceId)")
    } catch {
      logger.error("❌ Failed to unregister device: \(error.localizedDescription)")
      throw DeviceError.unregistrationFailed(error.localizedDescription)
    }
  }

  /// Update the FCM token for this device.
  ///
  /// Called when FCM token is refreshed.
  func updateToken(_ newToken: String) async throws {
    logger.info("🔄 updateToken() called")
    logger.info("   New token: \(newToken.prefix(20))...")

    guard let userId = authManager.currentUserId else {
      logger.warning("⚠️ No userId available for token update - skipping")
      return
    }

    logger.info("   userId: \(userId)")
    logger.info("   deviceId: \(self.deviceId)")

    let data: [String: Any] = [
      "userId": userId,
      "deviceId": deviceId,
      "fcmToken": newToken,
    ]

    do {
      logger.info("📞 Calling updateDeviceToken Cloud Function...")
      _ = try await Functions.functions(region: "us-central1")
        .httpsCallable("updateDeviceToken")
        .call(data)

      logger.info("✅ FCM token updated successfully")
      print("FCM token updated via Functions for device \(deviceId)")
    } catch {
      logger.error("❌ Failed to update FCM token: \(error.localizedDescription)")
      print("Failed to update FCM token: \(error)")
    }
  }

  /// Send a heartbeat to update lastSeen timestamp.
  func sendHeartbeat() async {
    logger.info("💓 sendHeartbeat() called")

    guard let userId = authManager.currentUserId else {
      logger.warning("⚠️ No userId available for heartbeat - skipping")
      return
    }

    logger.info("   userId: \(userId)")
    logger.info("   deviceId: \(self.deviceId)")

    let data: [String: Any] = [
      "userId": userId,
      "deviceId": deviceId,
    ]

    do {
      logger.info("📞 Calling deviceHeartbeat Cloud Function...")
      _ = try await Functions.functions(region: "us-central1")
        .httpsCallable("deviceHeartbeat")
        .call(data)
      logger.info("✅ Heartbeat sent successfully")
    } catch {
      logger.error("❌ Failed to send heartbeat: \(error.localizedDescription)")
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
