package com.pushed.android.service

import android.app.Notification
import android.content.pm.PackageManager
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.pushed.android.data.model.NotificationAction
import com.pushed.android.data.model.NotificationCategory
import com.pushed.android.data.model.NotificationPriority
import com.pushed.android.data.model.PushedNotification
import com.pushed.android.data.repository.NotificationRepository
import com.pushed.android.sync.WatchSyncManager
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.time.Instant
import java.util.UUID
import javax.inject.Inject

/**
 * Core notification listener service for Pushed.
 * 
 * Intercepts system notifications and transforms them into the shared contract format
 * for forwarding to the watchOS companion app.
 * 
 * This service requires the BIND_NOTIFICATION_LISTENER_SERVICE permission and
 * must be explicitly granted access by the user through system settings.
 */
@AndroidEntryPoint
class PushedNotificationListener : NotificationListenerService() {

    @Inject
    lateinit var notificationRepository: NotificationRepository

    @Inject
    lateinit var watchSyncManager: WatchSyncManager

    @Inject
    lateinit var notificationFilter: NotificationFilter

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.i(TAG, "NotificationListenerService connected")
        
        serviceScope.launch {
            notificationRepository.setListenerConnected(true)
            
            // Process any existing notifications that might have been missed
            processActiveNotifications()
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.i(TAG, "NotificationListenerService disconnected")
        
        serviceScope.launch {
            notificationRepository.setListenerConnected(false)
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        super.onNotificationPosted(sbn)
        
        // Skip our own notifications to avoid loops
        if (sbn.packageName == packageName) return
        
        serviceScope.launch {
            try {
                val shouldProcess = notificationFilter.shouldProcess(sbn)
                if (!shouldProcess) {
                    Log.d(TAG, "Filtered out notification from ${sbn.packageName}")
                    return@launch
                }

                val pushedNotification = transformNotification(sbn)
                
                // Save to local repository
                notificationRepository.insertNotification(pushedNotification)
                
                // Forward to watch
                watchSyncManager.sendNotification(pushedNotification)
                
                Log.d(TAG, "Processed notification: ${pushedNotification.title} from ${pushedNotification.appName}")
            } catch (e: Exception) {
                Log.e(TAG, "Error processing notification from ${sbn.packageName}", e)
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        super.onNotificationRemoved(sbn)
        
        if (sbn.packageName == packageName) return
        
        serviceScope.launch {
            try {
                val notificationId = generateStableId(sbn)
                
                // Mark as removed in repository
                notificationRepository.markNotificationRemoved(notificationId)
                
                // Notify watch of dismissal
                watchSyncManager.sendNotificationDismissal(notificationId)
                
                Log.d(TAG, "Notification removed: $notificationId")
            } catch (e: Exception) {
                Log.e(TAG, "Error handling notification removal", e)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        Log.i(TAG, "NotificationListenerService destroyed")
    }

    /**
     * Process all currently active notifications.
     * Called on listener connection to sync any notifications that arrived
     * while the listener was disconnected.
     */
    private suspend fun processActiveNotifications() {
        try {
            val activeNotifications = getActiveNotifications() ?: return
            
            Log.d(TAG, "Processing ${activeNotifications.size} active notifications")
            
            for (sbn in activeNotifications) {
                if (sbn.packageName == packageName) continue
                if (!notificationFilter.shouldProcess(sbn)) continue
                
                val pushedNotification = transformNotification(sbn)
                notificationRepository.insertNotification(pushedNotification)
            }
            
            // Trigger full sync with watch
            watchSyncManager.requestFullSync()
        } catch (e: Exception) {
            Log.e(TAG, "Error processing active notifications", e)
        }
    }

    /**
     * Transform a StatusBarNotification into the shared contract format.
     */
    private fun transformNotification(sbn: StatusBarNotification): PushedNotification {
        val notification = sbn.notification
        val extras = notification.extras

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val body = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()
        
        // Get conversation info if available
        val conversationTitle = extras.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE)?.toString()
        val senderName = notification.extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()

        return PushedNotification(
            id = generateStableId(sbn),
            schemaVersion = SCHEMA_VERSION,
            timestamp = Instant.ofEpochMilli(sbn.postTime),
            title = title,
            body = body,
            packageName = sbn.packageName,
            appName = getAppName(sbn.packageName),
            category = mapCategory(notification.category),
            priority = mapPriority(notification.priority),
            actions = extractActions(notification),
            groupKey = sbn.groupKey,
            isOngoing = sbn.isOngoing,
            isSilent = isSilentNotification(notification),
            color = notification.color.takeIf { it != 0 }?.let { 
                String.format("#%06X", 0xFFFFFF and it) 
            },
            subText = subText,
            conversationId = conversationTitle,
            senderName = senderName,
            iconData = null // Icon extraction handled separately for efficiency
        )
    }

    /**
     * Generate a stable, unique ID for the notification.
     * Uses package name, tag, and ID to create deterministic UUID.
     */
    private fun generateStableId(sbn: StatusBarNotification): String {
        val idSource = "${sbn.packageName}:${sbn.tag ?: ""}:${sbn.id}:${sbn.postTime}"
        return UUID.nameUUIDFromBytes(idSource.toByteArray()).toString()
    }

    /**
     * Get human-readable app name from package name.
     */
    private fun getAppName(packageName: String): String? {
        return try {
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }
    }

    /**
     * Map Android notification category to shared contract category.
     */
    private fun mapCategory(category: String?): NotificationCategory {
        return when (category) {
            Notification.CATEGORY_MESSAGE -> NotificationCategory.MESSAGE
            Notification.CATEGORY_EMAIL -> NotificationCategory.EMAIL
            Notification.CATEGORY_SOCIAL -> NotificationCategory.SOCIAL
            Notification.CATEGORY_PROMO -> NotificationCategory.PROMO
            Notification.CATEGORY_REMINDER -> NotificationCategory.REMINDER
            Notification.CATEGORY_CALL -> NotificationCategory.CALL
            Notification.CATEGORY_NAVIGATION, Notification.CATEGORY_TRANSPORT -> NotificationCategory.TRANSPORT
            Notification.CATEGORY_ALARM -> NotificationCategory.ALARM
            else -> NotificationCategory.OTHER
        }
    }

    /**
     * Map Android notification priority to shared contract priority.
     */
    private fun mapPriority(priority: Int): NotificationPriority {
        return when (priority) {
            Notification.PRIORITY_MIN -> NotificationPriority.MIN
            Notification.PRIORITY_LOW -> NotificationPriority.LOW
            Notification.PRIORITY_DEFAULT -> NotificationPriority.DEFAULT
            Notification.PRIORITY_HIGH -> NotificationPriority.HIGH
            Notification.PRIORITY_MAX -> NotificationPriority.MAX
            else -> NotificationPriority.DEFAULT
        }
    }

    /**
     * Extract available actions from notification.
     */
    private fun extractActions(notification: Notification): List<NotificationAction> {
        return notification.actions?.take(MAX_ACTIONS)?.map { action ->
            NotificationAction(
                id = UUID.randomUUID().toString(),
                label = action.title?.toString() ?: "Action",
                isDestructive = false, // Android doesn't have this concept natively
                requiresUnlock = action.extras.getBoolean(Notification.EXTRA_ALLOW_DURING_SETUP, false).not(),
                icon = null
            )
        } ?: emptyList()
    }

    /**
     * Check if notification should be delivered silently.
     */
    private fun isSilentNotification(notification: Notification): Boolean {
        val flags = notification.flags
        return (flags and Notification.FLAG_NO_CLEAR) != 0 ||
               notification.priority <= Notification.PRIORITY_LOW
    }

    companion object {
        private const val TAG = "PushedNotificationListener"
        private const val SCHEMA_VERSION = "1.0.0"
        private const val MAX_ACTIONS = 5
    }
}
