import FirebaseAuth
import FirebaseCore
import FirebaseFunctions
import Foundation
import os.log

/// Logger for notification fetching
private let logger = Logger(subsystem: "com.pushed.watch", category: "NotificationFetcher")

/// Service for fetching notifications via Firebase Cloud Functions.
///
/// Since Firestore SDK is not available on watchOS, this service uses
/// Cloud Functions to fetch and manage notifications. This provides
/// a polling alternative to push notifications (which require a paid
/// Apple Developer account).
@MainActor
@Observable
final class NotificationFetcher {

  // MARK: - State

  /// Whether a fetch is currently in progress
  var isFetching = false

  /// Last successful fetch timestamp
  var lastFetchTime: Date?

  /// Error from last fetch attempt
  var lastError: Error?

  /// Notifications fetched from Firebase
  var notifications: [PushedNotification] = []

  // MARK: - Dependencies

  private let functions: Functions

  // MARK: - Initialization

  init() {
    self.functions = Functions.functions(region: "us-central1")
    logger.info("🔧 NotificationFetcher initialized (Cloud Functions mode)")
  }

  // MARK: - Public Methods

  /// Fetch all notifications for the current user via Cloud Function.
  func fetchNotifications() async throws -> [PushedNotification] {
    logger.info("🔄 fetchNotifications() called")

    guard let userId = Auth.auth().currentUser?.uid else {
      logger.error("❌ No authenticated user")
      throw FetchError.notAuthenticated
    }

    isFetching = true
    lastError = nil

    defer {
      isFetching = false
    }

    do {
      logger.info("📡 Fetching notifications for user: \(userId)")

      // Call the getNotifications Cloud Function
      let payload: [String: Any] = [
        "userId": userId,
        "limit": 100,
      ]

      let result = try await functions.httpsCallable("getNotifications").call(payload)

      guard let data = result.data as? [String: Any],
        let notificationsData = data["notifications"] as? [[String: Any]]
      else {
        logger.error("❌ Invalid response format from getNotifications")
        throw FetchError.invalidData("Invalid response format")
      }

      logger.info("📥 Received \(notificationsData.count) notifications")

      let fetchedNotifications = notificationsData.compactMap {
        notificationDict
          -> PushedNotification? in
        do {
          return try parseNotification(from: notificationDict)
        } catch {
          logger.error("❌ Failed to parse notification: \(error.localizedDescription)")
          return nil
        }
      }

      notifications = fetchedNotifications
      lastFetchTime = Date()

      logger.info("✅ Successfully fetched \(fetchedNotifications.count) notifications")
      return fetchedNotifications

    } catch {
      logger.error("❌ Fetch failed: \(error.localizedDescription)")
      lastError = error
      throw FetchError.fetchFailed(error.localizedDescription)
    }
  }

  /// Start polling for notifications (simulates real-time updates).
  ///
  /// Since we can't use Firestore's real-time listeners on watchOS,
  /// this just does an initial fetch. For true real-time updates,
  /// you would implement a polling timer.
  func startListening() {
    logger.info("👂 Starting notification listener (polling mode)")

    Task {
      do {
        _ = try await fetchNotifications()
      } catch {
        logger.error("❌ Initial fetch failed: \(error.localizedDescription)")
        lastError = error
      }
    }
  }

  /// Stop listening (no-op in polling mode).
  func stopListening() {
    logger.info("🛑 Stopping notification listener")
    // No-op since we're not using real-time listeners
  }

  /// Dismiss a notification (delete from Firebase via Cloud Function).
  func dismissNotification(_ notification: PushedNotification) async throws {
    logger.info("🗑️ Dismissing notification: \(notification.id.uuidString)")

    guard let userId = Auth.auth().currentUser?.uid else {
      logger.error("❌ No authenticated user")
      throw FetchError.notAuthenticated
    }

    // Call the dismissNotification Cloud Function
    let payload: [String: Any] = [
      "userId": userId,
      "notificationId": notification.id.uuidString,
    ]

    do {
      _ = try await functions.httpsCallable("dismissNotification").call(payload)
      logger.info("✅ Notification dismissed successfully")

      // Remove from local array
      notifications.removeAll { $0.id == notification.id }

    } catch {
      logger.error("❌ Failed to dismiss notification: \(error.localizedDescription)")
      throw FetchError.dismissFailed(error.localizedDescription)
    }
  }

  /// Dismiss all notifications via Cloud Function.
  func dismissAllNotifications() async throws {
    logger.info("🗑️ Dismissing all notifications")

    guard let userId = Auth.auth().currentUser?.uid else {
      logger.error("❌ No authenticated user")
      throw FetchError.notAuthenticated
    }

    // Call the dismissAllNotifications Cloud Function
    let payload: [String: Any] = [
      "userId": userId
    ]

    do {
      let result = try await functions.httpsCallable("dismissAllNotifications").call(payload)

      if let data = result.data as? [String: Any],
        let deletedCount = data["deletedCount"] as? Int
      {
        logger.info("✅ Deleted \(deletedCount) notifications")
      }

      // Clear local array
      notifications = []

    } catch {
      logger.error("❌ Failed to dismiss all notifications: \(error.localizedDescription)")
      throw FetchError.dismissFailed(error.localizedDescription)
    }
  }

  // MARK: - Private Methods

  private func parseNotification(from data: [String: Any]) throws -> PushedNotification {
    // Parse required fields
    guard let id = data["id"] as? String,
      let uuid = UUID(uuidString: id)
    else {
      throw FetchError.invalidData("Invalid or missing ID")
    }

    guard let schemaVersion = data["schemaVersion"] as? String else {
      throw FetchError.invalidData("Missing schemaVersion")
    }

    guard let title = data["title"] as? String else {
      throw FetchError.invalidData("Missing title")
    }

    guard let packageName = data["packageName"] as? String else {
      throw FetchError.invalidData("Missing packageName")
    }

    // Parse timestamp (comes as ISO8601 string from Cloud Function)
    let timestamp: Date
    if let tsStr = data["timestamp"] as? String {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if let date = formatter.date(from: tsStr) {
        timestamp = date
      } else {
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        timestamp = formatter.date(from: tsStr) ?? Date()
      }
    } else if let tsNumber = data["timestamp"] as? Double {
      // Handle timestamp as epoch milliseconds
      timestamp = Date(timeIntervalSince1970: tsNumber / 1000)
    } else {
      timestamp = Date()
    }

    // Parse optional fields
    let body = data["body"] as? String
    let appName = data["appName"] as? String
    let categoryRaw = data["category"] as? String ?? "other"
    let category = NotificationCategory(rawValue: categoryRaw) ?? .other
    let priorityRaw = data["priority"] as? String ?? "default"
    let priority = NotificationPriority(rawValue: priorityRaw) ?? .default

    // Parse actions
    var actions: [NotificationAction] = []
    if let actionsData = data["actions"] as? [[String: Any]] {
      for actionData in actionsData {
        if let actionId = actionData["id"] as? String,
          let label = actionData["label"] as? String
        {
          actions.append(
            NotificationAction(
              id: actionId,
              label: label,
              isDestructive: actionData["isDestructive"] as? Bool ?? false,
              requiresUnlock: actionData["requiresUnlock"] as? Bool ?? false,
              icon: actionData["icon"] as? String
            ))
        }
      }
    }

    let groupKey = data["groupKey"] as? String
    let isOngoing = data["isOngoing"] as? Bool ?? false
    let isSilent = data["isSilent"] as? Bool ?? false
    let iconData = data["iconData"] as? String
    let color = data["color"] as? String
    let subText = data["subText"] as? String
    let conversationId = data["conversationId"] as? String
    let senderName = data["senderName"] as? String
    let sourceDeviceId = data["sourceDeviceId"] as? String

    // Parse createdAt
    var createdAt: Date? = nil
    if let createdAtStr = data["createdAt"] as? String {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      createdAt = formatter.date(from: createdAtStr)
      if createdAt == nil {
        formatter.formatOptions = [.withInternetDateTime]
        createdAt = formatter.date(from: createdAtStr)
      }
    }

    return PushedNotification(
      id: uuid,
      schemaVersion: schemaVersion,
      timestamp: timestamp,
      title: title,
      body: body,
      packageName: packageName,
      appName: appName,
      category: category,
      priority: priority,
      actions: actions,
      groupKey: groupKey,
      isOngoing: isOngoing,
      isSilent: isSilent,
      iconData: iconData,
      color: color,
      subText: subText,
      conversationId: conversationId,
      senderName: senderName,
      sourceDeviceId: sourceDeviceId,
      createdAt: createdAt
    )
  }
}

// MARK: - Errors

enum FetchError: LocalizedError {
  case notAuthenticated
  case fetchFailed(String)
  case dismissFailed(String)
  case invalidData(String)

  var errorDescription: String? {
    switch self {
    case .notAuthenticated:
      "User must be authenticated to fetch notifications"
    case .fetchFailed(let reason):
      "Failed to fetch notifications: \(reason)"
    case .dismissFailed(let reason):
      "Failed to dismiss notification: \(reason)"
    case .invalidData(let reason):
      "Invalid notification data: \(reason)"
    }
  }
}
