package com.pushed.android.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Broadcast receiver for system boot events.
 *
 * Ensures the notification listener service is active after device restart. The
 * NotificationListenerService should automatically restart, but this receiver provides additional
 * guarantees for maintaining persistent notification access.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, "android.intent.action.QUICKBOOT_POWERON" -> {
                Log.i(TAG, "Boot completed - Pushed services will be restored by system")

                // The NotificationListenerService is managed by the system and will be
                // automatically restarted if the user has granted permission.
                //
                // This receiver primarily serves as documentation that we handle boot
                // events and could be extended in the future for:
                // - Triggering sync operations after boot
                // - Sending heartbeat to Firebase
                // - Checking and requesting re-enablement of notification access if needed

                onBootCompleted(context)
            }
        }
    }

    /**
     * Handle boot completion event.
     *
     * Currently logs the event. Can be extended to:
     * - Perform initial sync check
     * - Register device with Firebase if needed
     * - Check notification listener status
     */
    private fun onBootCompleted(context: Context) {
        Log.d(TAG, "Processing boot completed event")

        // Note: We can't directly access Hilt-injected dependencies here
        // without using EntryPoints. For critical post-boot operations,
        // consider using WorkManager to schedule tasks.

        // The NotificationListenerService will be started by the system
        // when the enabled_notification_listeners setting includes our service.
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}
