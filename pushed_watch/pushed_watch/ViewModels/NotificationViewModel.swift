import Foundation

/// Main view model for managing notifications on the watch.
///
/// This class follows modern Swift concurrency patterns and uses
/// `@Observable` for reactive UI updates. Must be marked with
/// `@MainActor` per project guidelines.
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

  /// Connection state with Android device
  var isConnected = false

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
    syncService: NotificationSyncService? = nil,
    notificationStore: NotificationStore? = nil
  ) {
    self.syncService = syncService ?? NotificationSyncService()
    self.notificationStore = notificationStore ?? NotificationStore()

    Task {
      await loadNotifications()
      observeSyncUpdates()
    }
  }

  // MARK: - Public Methods

  /// Load notifications from local store
  func loadNotifications() async {
    isLoading = true
    errorMessage = nil

    do {
      notifications = try await notificationStore.loadAll()
    } catch {
      errorMessage = "Failed to load notifications: \(error.localizedDescription)"
    }

    isLoading = false
  }

  /// Refresh notifications from Android device
  func refreshNotifications() async {
    do {
      try await syncService.requestSync()
      await loadNotifications()
    } catch {
      errorMessage = "Sync failed: \(error.localizedDescription)"
    }
  }

  /// Delete a notification
  func deleteNotification(_ notification: PushedNotification) {
    Task {
      do {
        try await notificationStore.delete(notification)
        notifications.removeAll { $0.id == notification.id }
      } catch {
        errorMessage = "Failed to delete: \(error.localizedDescription)"
      }
    }
  }

  /// Dismiss a notification (notify Android)
  func dismissNotification(_ notification: PushedNotification) {
    Task {
      do {
        try await syncService.sendDismissal(for: notification.id)
        deleteNotification(notification)
      } catch {
        errorMessage = "Failed to dismiss: \(error.localizedDescription)"
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
      do {
        try await notificationStore.deleteAll()
        notifications = []
      } catch {
        errorMessage = "Failed to clear: \(error.localizedDescription)"
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
    // In a real implementation, this would observe WatchConnectivity updates
    // and update notifications accordingly
  }

  // MARK: - Preview Support

  /// Preview instance of NotificationViewModel.
  static var previewInstance: NotificationViewModel {
    let viewModel = NotificationViewModel()
    viewModel.notifications = [.preview]
    return viewModel
  }
}
