package com.pushed.android.sync

import android.util.Log
import com.pushed.android.auth.AuthManager
import com.pushed.android.data.model.PushedNotification
import com.pushed.android.data.repository.NotificationRepository
import com.pushed.android.firebase.NotificationUploader
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manager for synchronizing notifications with the watchOS companion app.
 * 
 * This class orchestrates the notification forwarding pipeline:
 * 1. Receives notifications from NotificationListenerService
 * 2. Uploads to Firebase Firestore
 * 3. Cloud Function triggers FCM dispatch to watchOS
 * 
 * Supports multi-device scenarios where the same user is signed into
 * multiple Android devices, all forwarding to shared watchOS receivers.
 */
@Singleton
class WatchSyncManager @Inject constructor(
    private val notificationRepository: NotificationRepository,
    private val notificationUploader: NotificationUploader,
    private val authManager: AuthManager,
    private val json: Json
) {

    private val _syncState = MutableStateFlow<SyncState>(SyncState.Idle)
    val syncState: StateFlow<SyncState> = _syncState.asStateFlow()

    private val _lastSyncTime = MutableStateFlow<Long?>(null)
    val lastSyncTime: StateFlow<Long?> = _lastSyncTime.asStateFlow()

    /**
     * Check if the user is authenticated and can sync notifications.
     */
    val canSync: Boolean
        get() = authManager.isAuthenticated

    /**
     * Send a single notification to the watch via Firebase.
     * Called immediately when a new notification is received.
     */
    suspend fun sendNotification(notification: PushedNotification) {
        // Skip if user is not authenticated
        if (!authManager.isAuthenticated) {
            Log.w(TAG, "User not authenticated, skipping notification sync")
            return
        }

        try {
            _syncState.value = SyncState.Syncing
            
            // Upload to Firebase Firestore
            // This triggers the Cloud Function which dispatches FCM to watchOS
            notificationUploader.uploadNotification(notification).fold(
                onSuccess = { notificationId ->
                    Log.d(TAG, "Notification uploaded successfully: $notificationId")
                    
                    // Mark as synced in local repository
                    notificationRepository.markNotificationsSynced(listOf(notification.id))
                    
                    _syncState.value = SyncState.Success
                    _lastSyncTime.value = System.currentTimeMillis()
                },
                onFailure = { error ->
                    Log.e(TAG, "Failed to upload notification", error)
                    _syncState.value = SyncState.Error(error.message ?: "Upload failed")
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error sending notification", e)
            _syncState.value = SyncState.Error(e.message ?: "Unknown error")
        }
    }

    /**
     * Send a notification dismissal event to the watch.
     * Called when a notification is removed on the Android side.
     */
    suspend fun sendNotificationDismissal(notificationId: String) {
        if (!authManager.isAuthenticated) {
            Log.w(TAG, "User not authenticated, skipping dismissal sync")
            return
        }

        try {
            // Delete from Firestore
            // The Cloud Function can optionally notify watches of the deletion
            notificationUploader.deleteNotification(notificationId).fold(
                onSuccess = {
                    Log.d(TAG, "Notification dismissal synced: $notificationId")
                },
                onFailure = { error ->
                    Log.e(TAG, "Failed to sync dismissal", error)
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error sending dismissal", e)
        }
    }

    /**
     * Request a full sync of all pending notifications.
     * Called on reconnection or when the watch requests a refresh.
     */
    suspend fun requestFullSync() {
        if (!authManager.isAuthenticated) {
            Log.w(TAG, "User not authenticated, skipping full sync")
            return
        }

        try {
            _syncState.value = SyncState.Syncing
            
            // Get all unsynced notifications from local repository
            val unsyncedNotifications = notificationRepository.getUnsyncedNotifications()
            
            if (unsyncedNotifications.isEmpty()) {
                Log.d(TAG, "No unsynced notifications for full sync")
                _syncState.value = SyncState.Success
                _lastSyncTime.value = System.currentTimeMillis()
                return
            }

            Log.d(TAG, "Full sync: uploading ${unsyncedNotifications.size} notifications")
            
            // Batch upload to Firestore
            notificationUploader.uploadNotifications(unsyncedNotifications).fold(
                onSuccess = { count ->
                    Log.i(TAG, "Full sync completed: $count notifications uploaded")
                    
                    // Mark all as synced
                    notificationRepository.markNotificationsSynced(
                        unsyncedNotifications.map { it.id }
                    )
                    
                    _syncState.value = SyncState.Success
                    _lastSyncTime.value = System.currentTimeMillis()
                },
                onFailure = { error ->
                    Log.e(TAG, "Full sync failed", error)
                    _syncState.value = SyncState.Error(error.message ?: "Sync failed")
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error during full sync", e)
            _syncState.value = SyncState.Error(e.message ?: "Unknown error")
        }
    }

    /**
     * Check if watch is currently reachable.
     * 
     * With Firebase-based sync, the "reachability" concept changes:
     * - We always attempt to upload to Firestore
     * - FCM handles delivery to watchOS when available
     * - This returns true if we can upload (user authenticated)
     */
    fun isWatchReachable(): Boolean {
        return authManager.isAuthenticated
    }

    companion object {
        private const val TAG = "WatchSyncManager"
    }
}

/**
 * Sync state for UI observation.
 */
sealed class SyncState {
    data object Idle : SyncState()
    data object Syncing : SyncState()
    data object Success : SyncState()
    data class Error(val message: String) : SyncState()
}

/**
 * Payload for notification dismissal events.
 */
@kotlinx.serialization.Serializable
data class DismissalPayload(
    val notificationId: String,
    val type: String = "dismissal"
)
