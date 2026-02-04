package com.pushed.android.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.pushed.android.data.model.PushedNotification
import kotlinx.coroutines.flow.Flow
import java.time.Instant

/**
 * Data Access Object for notification database operations.
 */
@Dao
interface NotificationDao {

    /**
     * Get all active (not removed) notifications, ordered by timestamp descending.
     */
    @Query("SELECT * FROM notifications WHERE isRemoved = 0 ORDER BY timestamp DESC")
    fun getActiveNotifications(): Flow<List<PushedNotification>>

    /**
     * Get notifications that haven't been synced to watch.
     */
    @Query("SELECT * FROM notifications WHERE isSynced = 0 AND isRemoved = 0 ORDER BY timestamp ASC")
    fun getUnsyncedNotifications(): Flow<List<PushedNotification>>

    /**
     * Get notifications that haven't been synced (one-shot query for batch operations).
     */
    @Query("SELECT * FROM notifications WHERE isSynced = 0 AND isRemoved = 0 ORDER BY timestamp ASC")
    suspend fun getUnsyncedNotificationsList(): List<PushedNotification>

    /**
     * Get a single notification by ID.
     */
    @Query("SELECT * FROM notifications WHERE id = :id LIMIT 1")
    suspend fun getNotificationById(id: String): PushedNotification?

    /**
     * Insert or update a notification.
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdate(notification: PushedNotification)

    /**
     * Insert multiple notifications.
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(notifications: List<PushedNotification>)

    /**
     * Mark a notification as removed.
     */
    @Query("UPDATE notifications SET isRemoved = 1 WHERE id = :id")
    suspend fun markAsRemoved(id: String)

    /**
     * Mark notifications as synced.
     */
    @Query("UPDATE notifications SET isSynced = 1, syncedAt = :syncedAt WHERE id IN (:ids)")
    suspend fun markAsSynced(ids: List<String>, syncedAt: Instant)

    /**
     * Delete notifications older than the specified timestamp.
     */
    @Query("DELETE FROM notifications WHERE timestamp < :cutoff")
    suspend fun deleteOlderThan(cutoff: Instant)

    /**
     * Delete all notifications.
     */
    @Query("DELETE FROM notifications")
    suspend fun deleteAll()

    /**
     * Get count of active notifications.
     */
    @Query("SELECT COUNT(*) FROM notifications WHERE isRemoved = 0")
    fun getActiveCount(): Flow<Int>

    /**
     * Get notifications by package name.
     */
    @Query("SELECT * FROM notifications WHERE packageName = :packageName AND isRemoved = 0 ORDER BY timestamp DESC")
    fun getByPackageName(packageName: String): Flow<List<PushedNotification>>

    /**
     * Get notifications by category.
     */
    @Query("SELECT * FROM notifications WHERE category = :category AND isRemoved = 0 ORDER BY timestamp DESC")
    fun getByCategory(category: String): Flow<List<PushedNotification>>
}
