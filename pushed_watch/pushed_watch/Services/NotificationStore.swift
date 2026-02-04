import Foundation

/// Local storage for notifications.
///
/// In a production app, this would use SwiftData for persistence.
/// This skeleton provides the interface for notification storage operations.
actor NotificationStore {
    
    // MARK: - In-Memory Store (Replace with SwiftData)
    
    private var notifications: [PushedNotification] = []
    
    // MARK: - CRUD Operations
    
    /// Load all notifications, sorted by timestamp (newest first)
    func loadAll() async throws -> [PushedNotification] {
        notifications.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Load a single notification by ID
    func load(id: UUID) async throws -> PushedNotification? {
        notifications.first { $0.id == id }
    }
    
    /// Save a notification (insert or update)
    func save(_ notification: PushedNotification) async throws {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = notification
        } else {
            notifications.append(notification)
        }
        
        // Enforce retention policy
        try await cleanupOld()
    }
    
    /// Save multiple notifications
    func saveAll(_ newNotifications: [PushedNotification]) async throws {
        for notification in newNotifications {
            try await save(notification)
        }
    }
    
    /// Delete a notification
    func delete(_ notification: PushedNotification) async throws {
        notifications.removeAll { $0.id == notification.id }
    }
    
    /// Delete all notifications
    func deleteAll() async throws {
        notifications.removeAll()
    }
    
    /// Delete notifications older than retention period
    func cleanupOld(retentionDays: Int = 7) async throws {
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        notifications.removeAll { $0.timestamp < cutoff }
    }
    
    // MARK: - Queries
    
    /// Get notifications by category
    func notifications(for category: NotificationCategory) async throws -> [PushedNotification] {
        notifications
            .filter { $0.category == category }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Get notifications by app
    func notifications(for packageName: String) async throws -> [PushedNotification] {
        notifications
            .filter { $0.packageName == packageName }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Get notification count
    func count() async throws -> Int {
        notifications.count
    }
    
    /// Get notifications since a specific date
    func notifications(since date: Date) async throws -> [PushedNotification] {
        notifications
            .filter { $0.timestamp >= date }
            .sorted { $0.timestamp > $1.timestamp }
    }
}
