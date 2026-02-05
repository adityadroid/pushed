import Foundation
import SwiftData
import WidgetKit

/// Local storage for notifications.
@MainActor
final class NotificationStore {

  private enum ComplicationKeys {
    static let unreadCount = "pushed_unread_count"
    static let latestTitle = "pushed_latest_title"
  }

  // MARK: - Dependencies

  private let modelContext: ModelContext
  private let userDefaults: UserDefaults

  // MARK: - Initialization

  init(modelContext: ModelContext, userDefaults: UserDefaults = .standard) {
    self.modelContext = modelContext
    self.userDefaults = userDefaults
    updateComplicationSnapshot()
  }

  // MARK: - CRUD Operations

  /// Load all notifications, sorted by timestamp (newest first)
  func loadAll() async throws -> [PushedNotification] {
    let descriptor = FetchDescriptor<StoredNotification>(
      sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
    )
    let stored = try modelContext.fetch(descriptor)
    return stored.map { $0.toPushedNotification() }
  }

  /// Load a single notification by ID
  func load(id: UUID) async throws -> PushedNotification? {
    let descriptor = FetchDescriptor<StoredNotification>(
      predicate: #Predicate { $0.id == id }
    )
    return try modelContext.fetch(descriptor).first?.toPushedNotification()
  }

  /// Save a notification (insert or update)
  func save(_ notification: PushedNotification) async throws {
    if let existing = try fetchStored(id: notification.id) {
      existing.update(from: notification)
    } else {
      modelContext.insert(StoredNotification(from: notification))
    }

    try await cleanupOld()
    try modelContext.save()
    updateComplicationSnapshot()
  }

  /// Save multiple notifications
  func saveAll(_ newNotifications: [PushedNotification]) async throws {
    for notification in newNotifications {
      if let existing = try fetchStored(id: notification.id) {
        existing.update(from: notification)
      } else {
        modelContext.insert(StoredNotification(from: notification))
      }
    }

    try await cleanupOld()
    try modelContext.save()
    updateComplicationSnapshot()
  }

  /// Delete a notification
  func delete(_ notification: PushedNotification) async throws {
    if let existing = try fetchStored(id: notification.id) {
      modelContext.delete(existing)
      try modelContext.save()
      updateComplicationSnapshot()
    }
  }

  /// Delete all notifications
  func deleteAll() async throws {
    let descriptor = FetchDescriptor<StoredNotification>()
    let stored = try modelContext.fetch(descriptor)
    stored.forEach { modelContext.delete($0) }
    try modelContext.save()
    updateComplicationSnapshot()
  }

  /// Delete notifications older than retention period
  func cleanupOld(retentionDays: Int = 7) async throws {
    let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
    let descriptor = FetchDescriptor<StoredNotification>(
      predicate: #Predicate { $0.timestamp < cutoff }
    )
    let oldItems = try modelContext.fetch(descriptor)
    guard !oldItems.isEmpty else { return }
    oldItems.forEach { modelContext.delete($0) }
  }

  // MARK: - Queries

  /// Get notifications by category
  func notifications(for category: NotificationCategory) async throws -> [PushedNotification] {
    let descriptor = FetchDescriptor<StoredNotification>(
      predicate: #Predicate { $0.categoryRaw == category.rawValue },
      sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
    )
    let stored = try modelContext.fetch(descriptor)
    return stored.map { $0.toPushedNotification() }
  }

  /// Get notifications by app
  func notifications(for packageName: String) async throws -> [PushedNotification] {
    let descriptor = FetchDescriptor<StoredNotification>(
      predicate: #Predicate { $0.packageName == packageName },
      sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
    )
    let stored = try modelContext.fetch(descriptor)
    return stored.map { $0.toPushedNotification() }
  }

  /// Get notification count
  func count() async throws -> Int {
    try modelContext.fetchCount(FetchDescriptor<StoredNotification>())
  }

  /// Get notifications since a specific date
  func notifications(since date: Date) async throws -> [PushedNotification] {
    let descriptor = FetchDescriptor<StoredNotification>(
      predicate: #Predicate { $0.timestamp >= date },
      sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
    )
    let stored = try modelContext.fetch(descriptor)
    return stored.map { $0.toPushedNotification() }
  }

  // MARK: - Private Helpers

  private func fetchStored(id: UUID) throws -> StoredNotification? {
    let descriptor = FetchDescriptor<StoredNotification>(
      predicate: #Predicate { $0.id == id }
    )
    return try modelContext.fetch(descriptor).first
  }

  private func updateComplicationSnapshot() {
    let count = (try? modelContext.fetchCount(FetchDescriptor<StoredNotification>())) ?? 0
    let latestDescriptor = FetchDescriptor<StoredNotification>(
      sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
    )
    let latestTitle = (try? modelContext.fetch(latestDescriptor).first)?.title

    let previousCount = userDefaults.integer(forKey: ComplicationKeys.unreadCount)
    let previousTitle = userDefaults.string(forKey: ComplicationKeys.latestTitle)

    userDefaults.set(count, forKey: ComplicationKeys.unreadCount)
    userDefaults.set(latestTitle, forKey: ComplicationKeys.latestTitle)

    if count != previousCount || latestTitle != previousTitle {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  // MARK: - Preview Support

  static func createPreviewStore() -> NotificationStore {
    let container = try! ModelContainer(
      for: StoredNotification.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return NotificationStore(modelContext: container.mainContext)
  }
}

// MARK: - StoredNotification Model

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
