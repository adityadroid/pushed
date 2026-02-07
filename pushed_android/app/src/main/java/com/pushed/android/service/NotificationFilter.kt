package com.pushed.android.service

import android.app.Notification
import android.service.notification.StatusBarNotification
import android.util.Log
import com.pushed.android.data.preferences.UserPreferences
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.first

/**
 * Filters notifications based on user preferences and system rules.
 *
 * Implements filtering logic to determine which notifications should be forwarded to the watchOS
 * companion app.
 */
@Singleton
class NotificationFilter @Inject constructor(private val userPreferences: UserPreferences) {

    /**
     * Determine if a notification should be processed and forwarded.
     *
     * @param sbn The StatusBarNotification to evaluate
     * @return true if the notification should be processed, false otherwise
     */
    suspend fun shouldProcess(sbn: StatusBarNotification): Boolean {
        val notification = sbn.notification

        // Skip group summaries (we handle individual notifications)
        if (isGroupSummary(notification)) {
            Log.v(TAG, "Skipping group summary from ${sbn.packageName}")
            return false
        }

        // Skip notifications from blocklisted packages
        if (isPackageBlocked(sbn.packageName)) {
            Log.d(TAG, "Skipping blocked package: ${sbn.packageName}")
            return false
        }

        // Skip ongoing notifications if user preference is set
        if (sbn.isOngoing && !userPreferences.forwardOngoingNotifications.first()) {
            Log.v(TAG, "Skipping ongoing notification from ${sbn.packageName}")
            return false
        }

        // Skip low priority notifications if user preference is set
        if (notification.priority <= Notification.PRIORITY_LOW &&
                        !userPreferences.forwardLowPriorityNotifications.first()
        ) {
            Log.v(TAG, "Skipping low priority notification from ${sbn.packageName}")
            return false
        }

        // Skip silent/ambient notifications if user preference is set
        if (isSilent(notification) && !userPreferences.forwardSilentNotifications.first()) {
            Log.v(TAG, "Skipping silent notification from ${sbn.packageName}")
            return false
        }

        // Check if category is enabled
        val category = notification.category ?: "other"
        if (!isCategoryEnabled(category)) {
            Log.d(TAG, "Skipping disabled category '$category' from ${sbn.packageName}")
            return false
        }

        return true
    }

    /**
     * Check if this notification is a group summary. Group summaries are metadata notifications
     * that summarize a group and should typically be skipped in favor of individual notifications.
     */
    private fun isGroupSummary(notification: Notification): Boolean {
        return (notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0
    }

    /** Check if the package is on the user's blocklist or system blocklist. */
    private suspend fun isPackageBlocked(packageName: String): Boolean {
        if (packageName in SYSTEM_BLOCKLIST) return true

        val blockedPackages = userPreferences.blockedPackages.first()
        return packageName in blockedPackages
    }

    /** Check if the notification category is enabled for forwarding. */
    private suspend fun isCategoryEnabled(category: String): Boolean {
        val enabledCategories = userPreferences.enabledCategories.first()
        // If no categories are explicitly enabled, allow all
        if (enabledCategories.isEmpty()) return true
        return category in enabledCategories
    }

    /** Check if the notification is silent/ambient. */
    private fun isSilent(notification: Notification): Boolean {
        return notification.priority <= Notification.PRIORITY_LOW ||
                (notification.flags and Notification.FLAG_NO_CLEAR) != 0
    }

    companion object {
        private const val TAG = "NotificationFilter"

        /** System packages that should always be filtered out. */
        val SYSTEM_BLOCKLIST =
                setOf(
                        "android",
                        "com.android.systemui",
                        "com.android.providers.downloads",
                        "com.android.vending" // Play Store download notifications
                )
    }
}
