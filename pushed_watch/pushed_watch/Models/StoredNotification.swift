import Foundation
import SwiftData

/// SwiftData persistence model for notifications.
@Model
final class StoredNotification {
  @Attribute(.unique) var id: UUID
  var schemaVersion: String
  var timestamp: Date
  var title: String
  var body: String?
  var packageName: String
  var appName: String?
  var categoryRaw: String
  var priorityRaw: String
  var actionsData: Data?
  var groupKey: String?
  var isOngoing: Bool
  var isSilent: Bool
  var iconData: String?
  var color: String?
  var subText: String?
  var conversationId: String?
  var senderName: String?
  var sourceDeviceId: String?
  var createdAt: Date?

  init(from notification: PushedNotification) {
    id = notification.id
    schemaVersion = notification.schemaVersion
    timestamp = notification.timestamp
    title = notification.title
    body = notification.body
    packageName = notification.packageName
    appName = notification.appName
    categoryRaw = notification.category.rawValue
    priorityRaw = notification.priority.rawValue
    actionsData = NotificationActionCodec.encode(notification.actions)
    groupKey = notification.groupKey
    isOngoing = notification.isOngoing
    isSilent = notification.isSilent
    iconData = notification.iconData
    color = notification.color
    subText = notification.subText
    conversationId = notification.conversationId
    senderName = notification.senderName
    sourceDeviceId = notification.sourceDeviceId
    createdAt = notification.createdAt
  }

  func update(from notification: PushedNotification) {
    schemaVersion = notification.schemaVersion
    timestamp = notification.timestamp
    title = notification.title
    body = notification.body
    packageName = notification.packageName
    appName = notification.appName
    categoryRaw = notification.category.rawValue
    priorityRaw = notification.priority.rawValue
    actionsData = NotificationActionCodec.encode(notification.actions)
    groupKey = notification.groupKey
    isOngoing = notification.isOngoing
    isSilent = notification.isSilent
    iconData = notification.iconData
    color = notification.color
    subText = notification.subText
    conversationId = notification.conversationId
    senderName = notification.senderName
    sourceDeviceId = notification.sourceDeviceId
    createdAt = notification.createdAt
  }

  func toPushedNotification() -> PushedNotification {
    PushedNotification(
      id: id,
      schemaVersion: schemaVersion,
      timestamp: timestamp,
      title: title,
      body: body,
      packageName: packageName,
      appName: appName,
      category: NotificationCategory(rawValue: categoryRaw) ?? .other,
      priority: NotificationPriority(rawValue: priorityRaw) ?? .default,
      actions: NotificationActionCodec.decode(actionsData),
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

private enum NotificationActionCodec {
  static func encode(_ actions: [NotificationAction]) -> Data? {
    guard !actions.isEmpty else { return nil }
    let encoder = JSONEncoder()
    return try? encoder.encode(actions)
  }

  static func decode(_ data: Data?) -> [NotificationAction] {
    guard let data else { return [] }
    let decoder = JSONDecoder()
    return (try? decoder.decode([NotificationAction].self, from: data)) ?? []
  }
}
