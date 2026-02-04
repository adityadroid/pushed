package com.pushed.android.data.repository

import com.pushed.android.data.local.NotificationDao
import com.pushed.android.data.model.PushedNotification
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.Instant
import java.time.temporal.ChronoUnit
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for managing notification data.
 * 
 * Provides a clean API for notification CRUD operations and
 * abstracts the underlying data sources.
 */
@Singleton
class NotificationRepository @Inject constructor(
    private val notificationDao: NotificationDao
) {

    private val _isListenerConnected = MutableStateFlow(false)
    val isListenerConnected: StateFlow<Boolean> = _isListenerConnected.asStateFlow()

    /**
     * Get all active (non-removed) notifications, newest first.
     */
    fun getActiveNotifications(): Flow<List<PushedNotification>> {
        return notificationDao.getActiveNotifications()
    }

    /**
     * Get notifications that haven't been synced to watch yet.
     */
    fun getUnsyncedNotificationsFlow(): Flow<List<PushedNotification>> {
        return notificationDao.getUnsyncedNotifications()
    }

    /**
     * Get unsynced notifications as a one-shot list for batch operations.
     */
    suspend fun getUnsyncedNotifications(): List<PushedNotification> {
        return notificationDao.getUnsyncedNotificationsList()
    }

    /**
     * Get a single notification by ID.
     */
    suspend fun getNotificationById(id: String): PushedNotification? {
        return notificationDao.getNotificationById(id)
    }

    /**
     * Insert or update a notification.
     */
    suspend fun insertNotification(notification: PushedNotification) {
        notificationDao.insertOrUpdate(notification)
    }

    /**
     * Mark a notification as removed (soft delete).
     */
    suspend fun markNotificationRemoved(id: String) {
        notificationDao.markAsRemoved(id)
    }

    /**
     * Mark notifications as synced to watch.
     */
    suspend fun markNotificationsSynced(ids: List<String>) {
        val syncedAt = Instant.now()
        notificationDao.markAsSynced(ids, syncedAt)
    }

    /**
     * Delete old notifications (beyond retention period).
     */
    suspend fun cleanupOldNotifications(retentionDays: Int = DEFAULT_RETENTION_DAYS) {
        val cutoff = Instant.now().minus(retentionDays.toLong(), ChronoUnit.DAYS)
        notificationDao.deleteOlderThan(cutoff)
    }

    /**
     * Delete all notifications (user-initiated clear).
     */
    suspend fun deleteAllNotifications() {
        notificationDao.deleteAll()
    }

    /**
     * Get count of active notifications.
     */
    fun getActiveNotificationCount(): Flow<Int> {
        return notificationDao.getActiveCount()
    }

    /**
     * Update listener connection state.
     */
    suspend fun setListenerConnected(connected: Boolean) {
        _isListenerConnected.value = connected
    }

    companion object {
        const val DEFAULT_RETENTION_DAYS = 7
    }
}
