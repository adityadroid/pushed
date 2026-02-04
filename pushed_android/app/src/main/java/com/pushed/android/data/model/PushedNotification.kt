package com.pushed.android.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.Serializable
import java.time.Instant

/**
 * Cross-platform notification data model.
 * 
 * This is the Android implementation of the shared contract defined in
 * /contract/notification_schema.json.
 * 
 * Used for:
 * - Local Room database storage
 * - JSON serialization for watch sync
 * - UI display
 */
@Entity(tableName = "notifications")
@Serializable
data class PushedNotification(
    @PrimaryKey
    val id: String,
    
    val schemaVersion: String = CURRENT_SCHEMA_VERSION,
    
    @Serializable(with = InstantSerializer::class)
    val timestamp: Instant,
    
    val title: String,
    
    val body: String? = null,
    
    val packageName: String,
    
    val appName: String? = null,
    
    val category: NotificationCategory = NotificationCategory.OTHER,
    
    val priority: NotificationPriority = NotificationPriority.DEFAULT,
    
    @Serializable(with = NotificationActionListSerializer::class)
    val actions: List<NotificationAction> = emptyList(),
    
    val groupKey: String? = null,
    
    val isOngoing: Boolean = false,
    
    val isSilent: Boolean = false,
    
    val iconData: String? = null,
    
    val color: String? = null,
    
    val subText: String? = null,
    
    val conversationId: String? = null,
    
    val senderName: String? = null,
    
    // Local-only fields (not synced)
    val isRemoved: Boolean = false,
    
    val isSynced: Boolean = false,
    
    @Serializable(with = InstantSerializer::class)
    val syncedAt: Instant? = null
) {
    companion object {
        const val CURRENT_SCHEMA_VERSION = "1.0.0"
    }
}

/**
 * Notification action button.
 */
@Serializable
data class NotificationAction(
    val id: String,
    val label: String,
    val isDestructive: Boolean = false,
    val requiresUnlock: Boolean = false,
    val icon: String? = null
)

/**
 * Notification category matching the shared contract.
 */
@Serializable
enum class NotificationCategory {
    MESSAGE,
    EMAIL,
    SOCIAL,
    NEWS,
    PROMO,
    REMINDER,
    CALL,
    TRANSPORT,
    ALARM,
    OTHER;
    
    companion object {
        fun fromString(value: String): NotificationCategory {
            return entries.find { it.name.equals(value, ignoreCase = true) } ?: OTHER
        }
    }
}

/**
 * Notification priority matching the shared contract.
 */
@Serializable
enum class NotificationPriority {
    MIN,
    LOW,
    DEFAULT,
    HIGH,
    MAX;
    
    companion object {
        fun fromString(value: String): NotificationPriority {
            return entries.find { it.name.equals(value, ignoreCase = true) } ?: DEFAULT
        }
    }
}
