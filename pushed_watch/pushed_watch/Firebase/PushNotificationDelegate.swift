import Combine
import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications
import WatchKit
import os.log

/// Logger for push notifications
private let pushLogger = Logger(subsystem: "com.pushed.watch", category: "PushNotification")

/// Delegate for handling Firebase Cloud Messaging on watchOS.
///
/// This is the core receiver for notifications forwarded from Android
/// devices through the Firebase middleware layer.
@MainActor
final class PushNotificationDelegate: NSObject, ObservableObject {
  var objectWillChange = ObservableObjectPublisher()

  // MARK: - Published State

  @Published var fcmToken: String? {
    didSet {
      pushLogger.info("🔑 fcmToken updated: \(self.fcmToken?.prefix(20) ?? "nil")...")
    }
  }
  @Published var lastReceivedNotification: PushedNotification?

  // MARK: - Callbacks

  var onNotificationReceived: ((PushedNotification) -> Void)?
  var onNotificationDeleted: ((String) -> Void)?
  var onTokenUpdated: ((String) -> Void)?

  // MARK: - Private

  private let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }()

  // MARK: - Initialization

  override init() {
    pushLogger.info("🔧 PushNotificationDelegate init() starting...")
    super.init()
    setupMessaging()
    requestNotificationPermissions()
    pushLogger.info("✅ PushNotificationDelegate init() complete")
  }

  // MARK: - Setup

  private func setupMessaging() {
    pushLogger.info("🔧 setupMessaging() called")
    Messaging.messaging().delegate = self
    pushLogger.info("✅ Set as Messaging delegate")

    // Get initial token
    Task {
      pushLogger.info("🔑 Fetching initial FCM token...")
      await fetchFCMToken()
    }
  }

  private func requestNotificationPermissions() {
    pushLogger.info("🔔 requestNotificationPermissions() called")
    let center = UNUserNotificationCenter.current()
    center.delegate = self

    Task {
      do {
        pushLogger.info("🔔 Requesting notification authorization...")
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        pushLogger.info("🔔 Notification permission granted: \(granted)")
        if granted {
          await MainActor.run {
            pushLogger.info("📱 Registering for remote notifications...")
            WKExtension.shared().registerForRemoteNotifications()
            pushLogger.info("✅ Registered for remote notifications")
          }
        } else {
          pushLogger.warning("⚠️ Notification permission denied by user")
        }
      } catch {
        pushLogger.error(
          "❌ Failed to request notification permissions: \(error.localizedDescription)")
        print("Failed to request notification permissions: \(error)")
      }
    }
  }

  // MARK: - Token Management

  /// Mock token prefix for development without APNs
  private static let mockTokenPrefix = "MOCK_FCM_TOKEN_"

  /// Whether we're using a mock token (APNs not available)
  var isUsingMockToken: Bool {
    fcmToken?.hasPrefix(Self.mockTokenPrefix) ?? false
  }

  /// Generate a mock FCM token for development
  private func generateMockToken() -> String {
    // Use device ID to make it consistent across app launches
    let deviceId = UserDefaults.standard.string(forKey: "pushed_device_id") ?? UUID().uuidString
    return "\(Self.mockTokenPrefix)\(deviceId)"
  }

  func fetchFCMToken() async {
    pushLogger.info("🔑 fetchFCMToken() called")
    do {
      let token = try await Messaging.messaging().token()
      pushLogger.info("✅ Got FCM token: \(token.prefix(20))...")
      self.fcmToken = token
      print("FCM Token: \(token)")

      pushLogger.info("📞 Calling onTokenUpdated callback...")
      onTokenUpdated?(token)
      pushLogger.info("✅ onTokenUpdated callback completed")
    } catch {
      pushLogger.error("❌ Failed to fetch FCM token: \(error.localizedDescription)")
      print("Failed to fetch FCM token: \(error)")

      // Check if this is the "No APNS token" error - use mock token for development
      let nsError = error as NSError
      if nsError.domain == "com.google.fcm" && nsError.code == 505 {
        pushLogger.warning("⚠️ APNs not available (no paid developer account?)")
        pushLogger.warning(
          "⚠️ Using MOCK FCM token for development - push notifications will NOT work!")

        let mockToken = generateMockToken()
        self.fcmToken = mockToken
        pushLogger.info("🔑 Generated mock token: \(mockToken.prefix(30))...")

        pushLogger.info("📞 Calling onTokenUpdated callback with mock token...")
        onTokenUpdated?(mockToken)
        pushLogger.info("✅ onTokenUpdated callback completed")
      }
    }
  }

  /// Get the current FCM token.
  /// Returns a mock token if APNs is not available (for development without paid Apple Developer account).
  func getToken() async throws -> String {
    pushLogger.info("🔑 getToken() called")
    if let token = fcmToken {
      if token.hasPrefix(Self.mockTokenPrefix) {
        pushLogger.warning("⚠️ Returning MOCK FCM token - push notifications will NOT work!")
      } else {
        pushLogger.info("✅ Returning cached FCM token: \(token.prefix(20))...")
      }
      return token
    }

    pushLogger.info("🔑 No cached token - fetching from Firebase...")
    do {
      let token = try await Messaging.messaging().token()
      pushLogger.info("✅ Got FCM token: \(token.prefix(20))...")
      self.fcmToken = token
      return token
    } catch {
      // Check if this is the "No APNS token" error - use mock token for development
      let nsError = error as NSError
      if nsError.domain == "com.google.fcm" && nsError.code == 505 {
        pushLogger.warning("⚠️ APNs not available - generating mock token for development")
        pushLogger.warning(
          "⚠️ Push notifications will NOT work without a paid Apple Developer account!")

        let mockToken = generateMockToken()
        self.fcmToken = mockToken
        pushLogger.info("🔑 Using mock token: \(mockToken.prefix(30))...")
        return mockToken
      }
      throw error
    }
  }
}

// MARK: - MessagingDelegate

extension PushNotificationDelegate: MessagingDelegate {

  nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?)
  {
    guard let token = fcmToken else {
      pushLogger.warning("⚠️ messaging:didReceiveRegistrationToken called with nil token")
      return
    }

    pushLogger.info("🔑 FCM token refreshed: \(token.prefix(20))...")
    print("FCM token refreshed: \(token)")

    Task { @MainActor in
      pushLogger.info("🔑 Updating stored FCM token...")
      self.fcmToken = token
      pushLogger.info("📞 Calling onTokenUpdated callback...")
      self.onTokenUpdated?(token)
      pushLogger.info("✅ Token update complete")
    }
  }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationDelegate: UNUserNotificationCenterDelegate {

  /// Handle notification received while app is in foreground.
  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo

    Task { @MainActor in
      handleNotificationPayload(userInfo)
    }

    // Show the notification even when app is in foreground
    completionHandler([.banner, .sound, .badge])
  }

  /// Handle notification tapped by user.
  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo

    Task { @MainActor in
      handleNotificationPayload(userInfo)
    }

    completionHandler()
  }

  // MARK: - Payload Processing

  private func handleNotificationPayload(_ userInfo: [AnyHashable: Any]) {
    // Check for deletion action
    if let action = userInfo["action"] as? String, action == "delete",
      let notificationId = userInfo["notificationId"] as? String
    {
      print("Received delete command for notification: \(notificationId)")
      onNotificationDeleted?(notificationId)
      return
    }

    // Extract notification data from FCM payload
    guard let notificationId = userInfo["notificationId"] as? String,
      let title = userInfo["title"] as? String ?? extractTitleFromAps(userInfo),
      let packageName = userInfo["packageName"] as? String
    else {
      print("Invalid notification payload")
      return
    }

    // Parse the notification from the data payload
    do {
      let notification = try parseNotificationFromPayload(userInfo)
      lastReceivedNotification = notification
      onNotificationReceived?(notification)
    } catch {
      print("Failed to parse notification: \(error)")
    }
  }

  private func parseNotificationFromPayload(_ userInfo: [AnyHashable: Any]) throws
    -> PushedNotification
  {
    // Convert userInfo to Data for decoding
    let data = try JSONSerialization.data(withJSONObject: userInfo)

    // Try to decode as PushedNotification
    // If that fails, construct from individual fields
    do {
      return try decoder.decode(PushedNotification.self, from: data)
    } catch {
      // Fallback: construct manually from individual fields
      guard let idString = userInfo["notificationId"] as? String,
        let id = UUID(uuidString: idString),
        let title = userInfo["title"] as? String ?? extractTitleFromAps(userInfo),
        let packageName = userInfo["packageName"] as? String
      else {
        throw PushError.invalidPayload
      }

      let schemaVersion = userInfo["schemaVersion"] as? String ?? "1.0.0"
      let body = userInfo["body"] as? String ?? extractBodyFromAps(userInfo)
      let appName = userInfo["appName"] as? String
      let categoryString = userInfo["category"] as? String ?? "other"
      let priorityString = userInfo["priority"] as? String ?? "default"
      let timestampString = userInfo["timestamp"] as? String
      let actions = parseActions(from: userInfo)
      let sourceDeviceId = userInfo["sourceDeviceId"] as? String
      let createdAt = parseDate(from: userInfo["createdAt"] as? String)
      let iconData = userInfo["iconData"] as? String
      let subText = userInfo["subText"] as? String
      let isOngoing = parseBool(from: userInfo["isOngoing"])
      let isSilent = parseBool(from: userInfo["isSilent"])

      let timestamp: Date
      if let ts = timestampString {
        timestamp = ISO8601DateFormatter().date(from: ts) ?? Date()
      } else {
        timestamp = Date()
      }

      return PushedNotification(
        id: id,
        schemaVersion: schemaVersion,
        timestamp: timestamp,
        title: title,
        body: body,
        packageName: packageName,
        appName: appName,
        category: NotificationCategory(rawValue: categoryString) ?? .other,
        priority: NotificationPriority(rawValue: priorityString) ?? .default,
        actions: actions,
        groupKey: userInfo["groupKey"] as? String,
        isOngoing: isOngoing,
        isSilent: isSilent,
        iconData: iconData,
        color: userInfo["color"] as? String,
        subText: subText,
        conversationId: userInfo["conversationId"] as? String,
        senderName: userInfo["senderName"] as? String,
        sourceDeviceId: sourceDeviceId,
        createdAt: createdAt
      )
    }
  }

  private func extractTitleFromAps(_ userInfo: [AnyHashable: Any]) -> String? {
    guard let aps = userInfo["aps"] as? [String: Any],
      let alert = aps["alert"] as? [String: Any]
    else {
      return nil
    }
    return alert["title"] as? String
  }

  private func extractBodyFromAps(_ userInfo: [AnyHashable: Any]) -> String? {
    guard let aps = userInfo["aps"] as? [String: Any],
      let alert = aps["alert"] as? [String: Any]
    else {
      return nil
    }
    return alert["body"] as? String
  }

  private func parseActions(from userInfo: [AnyHashable: Any]) -> [NotificationAction] {
    if let actionsJson = userInfo["actions"] as? String,
      let data = actionsJson.data(using: .utf8)
    {
      return (try? decoder.decode([NotificationAction].self, from: data)) ?? []
    }

    if let actionsArray = userInfo["actions"] {
      if let data = try? JSONSerialization.data(withJSONObject: actionsArray) {
        return (try? decoder.decode([NotificationAction].self, from: data)) ?? []
      }
    }

    return []
  }

  private func parseDate(from string: String?) -> Date? {
    guard let string else { return nil }
    return ISO8601DateFormatter().date(from: string)
  }

  private func parseBool(from value: Any?) -> Bool {
    if let boolValue = value as? Bool {
      return boolValue
    }
    if let stringValue = value as? String {
      return (stringValue as NSString).boolValue
    }
    return false
  }
}

// MARK: - Errors

enum PushError: LocalizedError {
  case invalidPayload
  case tokenNotAvailable

  var errorDescription: String? {
    switch self {
    case .invalidPayload:
      "Invalid notification payload"
    case .tokenNotAvailable:
      "FCM token not available"
    }
  }
}
