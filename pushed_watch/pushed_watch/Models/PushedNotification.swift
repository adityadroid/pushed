import Foundation

/// Cross-platform notification data model.
///
/// This is the watchOS implementation of the shared contract defined in
/// `/contract/notification_schema.json`.
///
/// Used for:
/// - JSON deserialization from Android sync
/// - SwiftData persistence
/// - SwiftUI display
struct PushedNotification: Codable, Identifiable, Hashable {
    
    /// Unique identifier for the notification (UUID v4)
    let id: UUID
    
    /// Schema version (semver format)
    let schemaVersion: String
    
    /// ISO 8601 timestamp when notification was received on Android
    let timestamp: Date
    
    /// Notification title text
    let title: String
    
    /// Notification body/content text
    let body: String?
    
    /// Android package name that posted the notification
    let packageName: String
    
    /// Human-readable application name
    let appName: String?
    
    /// Notification category for filtering
    let category: NotificationCategory
    
    /// Priority level
    let priority: NotificationPriority
    
    /// Available action buttons
    let actions: [NotificationAction]
    
    /// Key for grouping related notifications
    let groupKey: String?
    
    /// Whether this is an ongoing/persistent notification
    let isOngoing: Bool
    
    /// Whether the notification should be delivered silently
    let isSilent: Bool
    
    /// Base64-encoded PNG app icon (max 10KB decoded)
    let iconData: String?
    
    /// Accent color in hex format (e.g., #FF5722)
    let color: String?
    
    /// Secondary text displayed below the main content
    let subText: String?
    
    /// Identifier for messaging conversation threading
    let conversationId: String?
    
    /// Name of the sender for messaging notifications
    let senderName: String?
    
    // MARK: - Computed Properties
    
    /// Decoded icon image data
    var decodedIconData: Data? {
        guard let iconData else { return nil }
        return Data(base64Encoded: iconData)
    }
    
    /// Parsed accent color
    var accentColor: (red: Double, green: Double, blue: Double)? {
        guard let color, color.hasPrefix("#"), color.count == 7 else { return nil }
        
        let hex = String(color.dropFirst())
        guard let hexInt = UInt64(hex, radix: 16) else { return nil }
        
        return (
            red: Double((hexInt >> 16) & 0xFF) / 255.0,
            green: Double((hexInt >> 8) & 0xFF) / 255.0,
            blue: Double(hexInt & 0xFF) / 255.0
        )
    }
    
    /// Formatted timestamp for display
    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, schemaVersion, timestamp, title, body, packageName, appName
        case category, priority, actions, groupKey, isOngoing, isSilent
        case iconData, color, subText, conversationId, senderName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle UUID from string
        let idString = try container.decode(String.self, forKey: .id)
        guard let uuid = UUID(uuidString: idString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingKeys: [CodingKeys.id], debugDescription: "Invalid UUID format")
            )
        }
        id = uuid
        
        schemaVersion = try container.decode(String.self, forKey: .schemaVersion)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decodeIfPresent(String.self, forKey: .body)
        packageName = try container.decode(String.self, forKey: .packageName)
        appName = try container.decodeIfPresent(String.self, forKey: .appName)
        category = try container.decodeIfPresent(NotificationCategory.self, forKey: .category) ?? .other
        priority = try container.decodeIfPresent(NotificationPriority.self, forKey: .priority) ?? .default
        actions = try container.decodeIfPresent([NotificationAction].self, forKey: .actions) ?? []
        groupKey = try container.decodeIfPresent(String.self, forKey: .groupKey)
        isOngoing = try container.decodeIfPresent(Bool.self, forKey: .isOngoing) ?? false
        isSilent = try container.decodeIfPresent(Bool.self, forKey: .isSilent) ?? false
        iconData = try container.decodeIfPresent(String.self, forKey: .iconData)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        subText = try container.decodeIfPresent(String.self, forKey: .subText)
        conversationId = try container.decodeIfPresent(String.self, forKey: .conversationId)
        senderName = try container.decodeIfPresent(String.self, forKey: .senderName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(body, forKey: .body)
        try container.encode(packageName, forKey: .packageName)
        try container.encodeIfPresent(appName, forKey: .appName)
        try container.encode(category, forKey: .category)
        try container.encode(priority, forKey: .priority)
        try container.encode(actions, forKey: .actions)
        try container.encodeIfPresent(groupKey, forKey: .groupKey)
        try container.encode(isOngoing, forKey: .isOngoing)
        try container.encode(isSilent, forKey: .isSilent)
        try container.encodeIfPresent(iconData, forKey: .iconData)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encodeIfPresent(subText, forKey: .subText)
        try container.encodeIfPresent(conversationId, forKey: .conversationId)
        try container.encodeIfPresent(senderName, forKey: .senderName)
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PushedNotification, rhs: PushedNotification) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Memberwise initializer for manual construction
    init(id: UUID,
         schemaVersion: String,
         timestamp: Date,
         title: String,
         body: String?,
         packageName: String,
         appName: String?,
         category: NotificationCategory,
         priority: NotificationPriority,
         actions: [NotificationAction],
         groupKey: String?,
         isOngoing: Bool,
         isSilent: Bool,
         iconData: String?,
         color: String?,
         subText: String?,
         conversationId: String?,
         senderName: String?) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.timestamp = timestamp
        self.title = title
        self.body = body
        self.packageName = packageName
        self.appName = appName
        self.category = category
        self.priority = priority
        self.actions = actions
        self.groupKey = groupKey
        self.isOngoing = isOngoing
        self.isSilent = isSilent
        self.iconData = iconData
        self.color = color
        self.subText = subText
        self.conversationId = conversationId
        self.senderName = senderName
    }
}

// MARK: - Supporting Types

/// Notification action button.
struct NotificationAction: Codable, Identifiable, Hashable {
    let id: String
    let label: String
    let isDestructive: Bool
    let requiresUnlock: Bool
    let icon: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        label = try container.decode(String.self, forKey: .label)
        isDestructive = try container.decodeIfPresent(Bool.self, forKey: .isDestructive) ?? false
        requiresUnlock = try container.decodeIfPresent(Bool.self, forKey: .requiresUnlock) ?? false
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
    }
}

/// Notification category matching the shared contract.
enum NotificationCategory: String, Codable, CaseIterable {
    case message
    case email
    case social
    case news
    case promo
    case reminder
    case call
    case transport
    case alarm
    case other
    
    /// SF Symbol for the category
    var iconName: String {
        switch self {
        case .message: "message.fill"
        case .email: "envelope.fill"
        case .social: "person.2.fill"
        case .news: "newspaper.fill"
        case .promo: "tag.fill"
        case .reminder: "bell.fill"
        case .call: "phone.fill"
        case .transport: "car.fill"
        case .alarm: "alarm.fill"
        case .other: "app.fill"
        }
    }
    
    /// Display name for the category
    var displayName: String {
        switch self {
        case .message: "Messages"
        case .email: "Email"
        case .social: "Social"
        case .news: "News"
        case .promo: "Promotions"
        case .reminder: "Reminders"
        case .call: "Calls"
        case .transport: "Transport"
        case .alarm: "Alarms"
        case .other: "Other"
        }
    }
}

/// Notification priority matching the shared contract.
enum NotificationPriority: String, Codable, CaseIterable, Comparable {
    case min
    case low
    case `default`
    case high
    case max
    
    private var sortOrder: Int {
        switch self {
        case .min: 0
        case .low: 1
        case .default: 2
        case .high: 3
        case .max: 4
        }
    }
    
    static func < (lhs: NotificationPriority, rhs: NotificationPriority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Schema Version

struct SchemaVersion {
    static let current = "1.0.0"
    
    static func isCompatible(_ version: String) -> Bool {
        // Parse major version
        let components = version.split(separator: ".")
        guard let major = components.first.flatMap({ Int($0) }) else {
            return false
        }
        
        let currentComponents = current.split(separator: ".")
        guard let currentMajor = currentComponents.first.flatMap({ Int($0) }) else {
            return false
        }
        
        // Same major version is compatible
        return major == currentMajor
    }
}
