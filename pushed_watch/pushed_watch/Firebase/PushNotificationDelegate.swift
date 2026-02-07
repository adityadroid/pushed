import Combine
import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications
import WatchKit

/// Delegate for handling Firebase Cloud Messaging on watchOS.
///
/// This is the core receiver for notifications forwarded from Android
/// devices through the Firebase middleware layer.
@MainActor
final class PushNotificationDelegate: NSObject, ObservableObject {
  var objectWillChange = ObservableObjectPublisher()

  // MARK: - Published State

  @Published var fcmToken: String?
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
    super.init()
    setupMessaging()
    requestNotificationPermissions()
  }

  // MARK: - Setup

  private func setupMessaging() {
    Messaging.messaging().delegate = self

    // Get initial token
    Task {
      await fetchFCMToken()
    }
  }

  private func requestNotificationPermissions() {
    let center = UNUserNotificationCenter.current()
    center.delegate = self

    Task {
      do {
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        if granted {
          await MainActor.run {
            WKExtension.shared().registerForRemoteNotifications()
          }
        }
      } catch {
        print("Failed to request notification permissions: \(error)")
      }
    }
  }

  // MARK: - Token Management

  func fetchFCMToken() async {
    do {
      let token = try await Messaging.messaging().token()
      self.fcmToken = token
      print("FCM Token: \(token)")
      onTokenUpdated?(token)
    } catch {
      print("Failed to fetch FCM token: \(error)")
    }
  }

  /// Get the current FCM token.
  func getToken() async throws -> String {
    if let token = fcmToken {
      return token
    }

    let token = try await Messaging.messaging().token()
    self.fcmToken = token
    return token
  }
}

// MARK: - MessagingDelegate

extension PushNotificationDelegate: MessagingDelegate {

  nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?)
  {
    guard let token = fcmToken else { return }

    print("FCM token refreshed: \(token)")

    Task { @MainActor in
      self.fcmToken = token
      self.onTokenUpdated?(token)
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
