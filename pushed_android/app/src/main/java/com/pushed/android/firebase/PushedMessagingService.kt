package com.pushed.android.firebase

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Firebase Cloud Messaging service for handling token refreshes.
 * 
 * On Android, this primarily handles:
 * - FCM token refresh events
 * - (Optional) Receiving sync commands from the server
 * 
 * Note: The main notification flow is Android → Firebase → watchOS,
 * so Android doesn't typically receive FCM notifications in this system.
 */
@AndroidEntryPoint
class PushedMessagingService : FirebaseMessagingService() {

    @Inject
    lateinit var deviceManager: DeviceManager

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    /**
     * Called when FCM token is refreshed.
     * 
     * This happens when:
     * - App is restored to a new device
     * - User uninstalls/reinstalls the app
     * - User clears app data
     * - Token expires (rare)
     */
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.i(TAG, "FCM token refreshed")

        serviceScope.launch {
            deviceManager.updateFcmToken(token).fold(
                onSuccess = {
                    Log.i(TAG, "Successfully updated FCM token in Firestore")
                },
                onFailure = { e ->
                    Log.e(TAG, "Failed to update FCM token", e)
                }
            )
        }
    }

    /**
     * Called when a message is received.
     * 
     * For the Pushed system, Android devices typically don't receive
     * FCM messages (they send notifications via Firestore).
     * 
     * However, this can be used for:
     * - Sync commands from the server
     * - Configuration updates
     * - Device management commands
     */
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d(TAG, "FCM message received from: ${remoteMessage.from}")

        val data = remoteMessage.data
        if (data.isNotEmpty()) {
            Log.d(TAG, "Message data: $data")

            when (data["type"]) {
                "sync_command" -> handleSyncCommand(data)
                "config_update" -> handleConfigUpdate(data)
                else -> Log.d(TAG, "Unknown message type: ${data["type"]}")
            }
        }
    }

    /**
     * Handle sync command from server.
     */
    private fun handleSyncCommand(data: Map<String, String>) {
        Log.d(TAG, "Sync command received: ${data["command"]}")
        // Could trigger a full sync or specific actions
    }

    /**
     * Handle configuration update from server.
     */
    private fun handleConfigUpdate(data: Map<String, String>) {
        Log.d(TAG, "Config update received")
        // Could update local configuration
    }

    companion object {
        private const val TAG = "PushedMessagingService"
    }
}
