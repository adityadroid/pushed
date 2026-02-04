package com.pushed.android.firebase

import android.util.Log
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.pushed.android.auth.AuthManager
import com.pushed.android.data.model.NotificationAction
import com.pushed.android.data.model.PushedNotification
import kotlinx.coroutines.tasks.await
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manager for uploading notifications to Firestore.
 * 
 * This is the core component that writes notifications to the Firebase
 * middleware layer, triggering the Cloud Function to dispatch FCM
 * to registered watchOS devices.
 * 
 * Architecture:
 * 1. Android NotificationListenerService intercepts notification
 * 2. NotificationUploader writes to Firestore
 * 3. Cloud Function triggers on document create
 * 4. FCM dispatched to registered watchOS devices
 */
@Singleton
class NotificationUploader @Inject constructor(
    private val firestore: FirebaseFirestore,
    private val authManager: AuthManager,
    private val deviceManager: DeviceManager
) {

    private val dateFormatter = DateTimeFormatter.ISO_INSTANT

    /**
     * Upload a notification to Firestore for forwarding to watchOS.
     * 
     * @param notification The notification to upload
     * @return Result indicating success or failure
     */
    suspend fun uploadNotification(notification: PushedNotification): Result<String> {
        val userId = authManager.currentUserId
            ?: return Result.failure(IllegalStateException("User must be authenticated to upload notifications"))

        val deviceId = deviceManager.getDeviceId()

        return try {
            val notificationData = buildNotificationData(notification, deviceId)

            val docRef = firestore
                .collection("users")
                .document(userId)
                .collection("notifications")
                .document(notification.id)

            docRef.set(notificationData).await()

            Log.i(TAG, "Notification uploaded: ${notification.id} from device $deviceId")
            Result.success(notification.id)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to upload notification", e)
            Result.failure(e)
        }
    }

    /**
     * Upload multiple notifications in a batch.
     * 
     * @param notifications List of notifications to upload
     * @return Result containing count of successfully uploaded notifications
     */
    suspend fun uploadNotifications(notifications: List<PushedNotification>): Result<Int> {
        val userId = authManager.currentUserId
            ?: return Result.failure(IllegalStateException("User must be authenticated"))

        val deviceId = deviceManager.getDeviceId()

        return try {
            val batch = firestore.batch()
            val notificationsRef = firestore
                .collection("users")
                .document(userId)
                .collection("notifications")

            for (notification in notifications) {
                val docRef = notificationsRef.document(notification.id)
                val data = buildNotificationData(notification, deviceId)
                batch.set(docRef, data)
            }

            batch.commit().await()

            Log.i(TAG, "Batch uploaded ${notifications.size} notifications")
            Result.success(notifications.size)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to batch upload notifications", e)
            Result.failure(e)
        }
    }

    /**
     * Delete a notification from Firestore.
     * 
     * Called when a notification is dismissed on Android.
     */
    suspend fun deleteNotification(notificationId: String): Result<Unit> {
        val userId = authManager.currentUserId
            ?: return Result.failure(IllegalStateException("User must be authenticated"))

        return try {
            firestore
                .collection("users")
                .document(userId)
                .collection("notifications")
                .document(notificationId)
                .delete()
                .await()

            Log.i(TAG, "Notification deleted: $notificationId")
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to delete notification", e)
            Result.failure(e)
        }
    }

    /**
     * Build the Firestore document data from a PushedNotification.
     */
    private fun buildNotificationData(
        notification: PushedNotification,
        sourceDeviceId: String
    ): Map<String, Any?> {
        return buildMap {
            put("id", notification.id)
            put("schemaVersion", notification.schemaVersion)
            put("timestamp", notification.timestamp.atOffset(ZoneOffset.UTC).format(dateFormatter))
            put("title", notification.title)
            put("body", notification.body)
            put("packageName", notification.packageName)
            put("appName", notification.appName)
            put("category", notification.category.name.lowercase())
            put("priority", notification.priority.name.lowercase())
            put("actions", notification.actions.map { action ->
                mapOf(
                    "id" to action.id,
                    "label" to action.label,
                    "isDestructive" to action.isDestructive,
                    "requiresUnlock" to action.requiresUnlock,
                    "icon" to action.icon
                )
            })
            put("groupKey", notification.groupKey)
            put("isOngoing", notification.isOngoing)
            put("isSilent", notification.isSilent)
            put("iconData", notification.iconData)
            put("color", notification.color)
            put("subText", notification.subText)
            put("conversationId", notification.conversationId)
            put("senderName", notification.senderName)
            put("sourceDeviceId", sourceDeviceId)
            put("createdAt", FieldValue.serverTimestamp())
        }
    }

    companion object {
        private const val TAG = "NotificationUploader"
    }
}
