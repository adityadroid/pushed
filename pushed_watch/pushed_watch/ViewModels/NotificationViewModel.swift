import Foundation
import Observation
import SwiftData

/// Main view model for managing notifications on the watch.
///
/// This class follows modern Swift concurrency patterns and uses
/// `@Observable` for reactive UI updates. Must be marked with
/// `@MainActor` per project guidelines.
///
/// Supports two modes of operation:
/// 1. Push-based: Receives notifications via FCM push (requires paid developer account)
/// 2. Poll-based: Fetches notifications directly from Firestore (no paid account needed)
@MainActor
@Observable
final class NotificationViewModel {

  // MARK: - Published State

  /// All notifications, sorted by timestamp (newest first)
  var notifications: [PushedNotification] = []

  /// Whether data is currently being loaded
  var isLoading = false

  /// Current error message, if any
  var errorMessage: String?

  /// Connection state with Firebase
  var isConnected = false

  /// Last refresh time
  var lastRefreshTime: Date?

  /// Reference to the notification fetcher (for polling mode)
  var notificationFetcher: NotificationFetcher?

  /// Whether we're using Firestore polling mode
  var isPollingMode: Bool {
    notificationFetcher != nil
  }

  // MARK: - Computed Properties

  /// Notifications grouped by date (for section headers)
  var groupedNotifications: [Date: [PushedNotification]] {
    Dictionary(grouping: notifications) { notification in
      Calendar.current.startOfDay(for: notification.timestamp)
    }
  }

  /// Unread notification count (for complications)
  var unreadCount: Int {
    notifications.count
  }

  /// High priority notifications
  var highPriorityNotifications: [PushedNotification] {
    notifications.filter { $0.priority >= .high }
  }

  // MARK: - Dependencies

  private let syncService: NotificationSyncService
  private let notificationStore: NotificationStore

  // MARK: - Initialization

  init(
    syncService: NotificationSyncService,
    notificationStore: NotificationStore,
    notificationFetcher: NotificationFetcher? = nil
  ) {
    self.syncService = syncService
    self.notificationStore = notificationStore
    self.notificationFetcher = notificationFetcher

    Task {
      await loadNotifications()
      observeSyncUpdates()
    }
  }

  /// Enable Firestore polling mode (for apps without push notification capability).
  func enablePollingMode(fetcher: NotificationFetcher) {
    self.notificationFetcher = fetcher

    // Start real-time listening
    fetcher.startListening()

    // Observe fetcher updates
    Task {
      observeFetcherUpdates()
    }
  }

  // MARK: - Public Methods

  /// Load notifications from local store
  func loadNotifications() async {
    isLoading = true
    errorMessage = nil

    // If in polling mode, fetch from Firestore
    if let fetcher = notificationFetcher {
      do {
        notifications = try await fetcher.fetchNotifications()
        lastRefreshTime = Date()
      } catch {
        errorMessage = "Failed to load notifications: \(error.localizedDescription)"
      }
    } else {
      // Use local store
      do {
        notifications = try await notificationStore.loadAll()
      } catch {
        errorMessage = "Failed to load notifications: \(error.localizedDescription)"
      }
    }

    isLoading = false
  }

  /// Refresh notifications from Firebase
  func refreshNotifications() async {
    isLoading = true
    errorMessage = nil

    if let fetcher = notificationFetcher {
      // Poll mode: fetch from Firestore
      do {
        notifications = try await fetcher.fetchNotifications()
        lastRefreshTime = Date()
      } catch {
        errorMessage = "Refresh failed: \(error.localizedDescription)"
      }
    } else {
      // Push mode: request sync
      do {
        try await syncService.requestSync()
        await loadNotifications()
      } catch {
        errorMessage = "Sync failed: \(error.localizedDescription)"
      }
    }

    isLoading = false
  }

  /// Delete a notification
  func deleteNotification(_ notification: PushedNotification) {
    Task {
      if let fetcher = notificationFetcher {
        // Poll mode: dismiss from Firestore
        do {
          try await fetcher.dismissNotification(notification)
          notifications.removeAll { $0.id == notification.id }
        } catch {
          errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
      } else {
        // Push mode: delete from local store
        do {
          try await notificationStore.delete(notification)
          notifications.removeAll { $0.id == notification.id }
        } catch {
          errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
      }
    }
  }

  /// Remove a notification by ID (called from remote deletion)
  func removeNotification(withId id: String) {
    if let index = notifications.firstIndex(where: { $0.id.uuidString == id }) {
      let notification = notifications[index]
      deleteNotification(notification)
    }
  }

  /// Dismiss a notification (notify Firebase and remove locally)
  func dismissNotification(_ notification: PushedNotification) {
    Task {
      if let fetcher = notificationFetcher {
        // Poll mode: dismiss from Firestore
        do {
          try await fetcher.dismissNotification(notification)
        } catch {
          errorMessage = "Failed to dismiss: \(error.localizedDescription)"
        }
      } else {
        // Push mode: send dismissal and delete locally
        do {
          try await syncService.sendDismissal(for: notification.id)
          deleteNotification(notification)
        } catch {
          errorMessage = "Failed to dismiss: \(error.localizedDescription)"
        }
      }
    }
  }

  /// Execute an action on a notification
  func executeAction(_ action: NotificationAction, for notification: PushedNotification) {
    Task {
      do {
        try await syncService.sendAction(action, for: notification.id)
      } catch {
        errorMessage = "Action failed: \(error.localizedDescription)"
      }
    }
  }

  /// Clear all notifications
  func clearAll() {
    Task {
      if let fetcher = notificationFetcher {
        // Poll mode: dismiss all from Firestore
        do {
          try await fetcher.dismissAllNotifications()
          notifications = []
        } catch {
          errorMessage = "Failed to clear: \(error.localizedDescription)"
        }
      } else {
        // Push mode: delete all from local store
        do {
          try await notificationStore.deleteAll()
          notifications = []
        } catch {
          errorMessage = "Failed to clear: \(error.localizedDescription)"
        }
      }
    }
  }

  /// Add a notification received from FCM push.
  ///
  /// This is called when a new notification arrives via Firebase Cloud Messaging.
  /// The notification is added to the local store and UI is updated.
  func addNotification(_ notification: PushedNotification) {
    Task {
      do {
        // Save to local store
        try await notificationStore.save(notification)

        // Insert at the beginning (newest first)
        if !notifications.contains(where: { $0.id == notification.id }) {
          notifications.insert(notification, at: 0)
        }
      } catch {
        errorMessage = "Failed to save notification: \(error.localizedDescription)"
      }
    }
  }

  // MARK: - Private Methods

  private func observeSyncUpdates() {
    isConnected = syncService.isReachable

    withObservationTracking {
      _ = syncService.isReachable
    } onChange: {
      Task { @MainActor [weak self] in
        guard let self else { return }
        self.isConnected = self.syncService.isReachable
        self.observeSyncUpdates()
      }
    }
  }

  private func observeFetcherUpdates() {
    guard let fetcher = notificationFetcher else { return }

    withObservationTracking {
      _ = fetcher.notifications
    } onChange: {
      Task { @MainActor [weak self] in
        guard let self, let fetcher = self.notificationFetcher else { return }
        self.notifications = fetcher.notifications
        self.lastRefreshTime = fetcher.lastFetchTime
        self.observeFetcherUpdates()
      }
    }
  }

  // MARK: - Preview Support

  /// Preview instance of NotificationViewModel.
  static var previewInstance: NotificationViewModel {
    let store = NotificationStore.createPreviewStore()
    let viewModel = NotificationViewModel(
      syncService: NotificationSyncService(),
      notificationStore: store
    )
    viewModel.notifications = [PushedNotification.preview]
    return viewModel
  }

  /// Preview instance with multiple notifications for testing.
  static var previewInstanceWithMultipleNotifications: NotificationViewModel {
    let store = NotificationStore.createPreviewStore()
    let viewModel = NotificationViewModel(
      syncService: NotificationSyncService(),
      notificationStore: store
    )

    // Create sample notifications
    let now = Date()
    viewModel.notifications = [
      PushedNotification(
        id: UUID(),
        schemaVersion: "1.0.0",
        timestamp: now,
        title: "New Message from John",
        body: "Hey! Are you coming to the party tonight? Let me know!",
        packageName: "com.whatsapp",
        appName: "WhatsApp",
        category: .message,
        priority: .high,
        actions: [],
        groupKey: nil,
        isOngoing: false,
        isSilent: false,
        iconData: nil,
        color: "#25D366",
        subText: nil,
        conversationId: nil,
        senderName: "John Doe",
        sourceDeviceId: "device123",
        createdAt: now
      ),
      PushedNotification(
        id: UUID(),
        schemaVersion: "1.0.0",
        timestamp: now.addingTimeInterval(-300),
        title: "Your order has shipped!",
        body: "Your package is on its way. Track your delivery in the app.",
        packageName: "com.amazon.mShop.android.shopping",
        appName: "Amazon",
        category: .promo,
        priority: .default,
        actions: [],
        groupKey: nil,
        isOngoing: false,
        isSilent: false,
        iconData: nil,
        color: "#FF9900",
        subText: nil,
        conversationId: nil,
        senderName: nil,
        sourceDeviceId: "device123",
        createdAt: now.addingTimeInterval(-300)
      ),
      PushedNotification(
        id: UUID(),
        schemaVersion: "1.0.0",
        timestamp: now.addingTimeInterval(-3600),
        title: "Meeting in 15 minutes",
        body: "Team standup - Conference Room B",
        packageName: "com.google.android.calendar",
        appName: "Calendar",
        category: .reminder,
        priority: .high,
        actions: [],
        groupKey: nil,
        isOngoing: false,
        isSilent: false,
        iconData: nil,
        color: "#4285F4",
        subText: nil,
        conversationId: nil,
        senderName: nil,
        sourceDeviceId: "device123",
        createdAt: now.addingTimeInterval(-3600)
      ),
    ]

    return viewModel
  }
}
