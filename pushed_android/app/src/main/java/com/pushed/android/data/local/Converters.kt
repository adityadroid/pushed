package com.pushed.android.data.local

import androidx.room.TypeConverter
import com.pushed.android.data.model.NotificationAction
import com.pushed.android.data.model.NotificationCategory
import com.pushed.android.data.model.NotificationPriority
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.time.Instant

/**
 * Room type converters for complex data types.
 */
class Converters {
    
    private val json = Json { ignoreUnknownKeys = true }

    // Instant converters
    @TypeConverter
    fun fromInstant(instant: Instant?): Long? {
        return instant?.toEpochMilli()
    }

    @TypeConverter
    fun toInstant(epochMilli: Long?): Instant? {
        return epochMilli?.let { Instant.ofEpochMilli(it) }
    }

    // NotificationCategory converters
    @TypeConverter
    fun fromCategory(category: NotificationCategory): String {
        return category.name
    }

    @TypeConverter
    fun toCategory(value: String): NotificationCategory {
        return NotificationCategory.fromString(value)
    }

    // NotificationPriority converters
    @TypeConverter
    fun fromPriority(priority: NotificationPriority): String {
        return priority.name
    }

    @TypeConverter
    fun toPriority(value: String): NotificationPriority {
        return NotificationPriority.fromString(value)
    }

    // List<NotificationAction> converters
    @TypeConverter
    fun fromActionsList(actions: List<NotificationAction>): String {
        return json.encodeToString(actions)
    }

    @TypeConverter
    fun toActionsList(value: String): List<NotificationAction> {
        return try {
            json.decodeFromString(value)
        } catch (e: Exception) {
            emptyList()
        }
    }
}
