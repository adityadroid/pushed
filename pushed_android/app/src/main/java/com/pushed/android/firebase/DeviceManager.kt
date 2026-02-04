package com.pushed.android.firebase

import android.os.Build
import android.provider.Settings
import android.util.Log
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import com.google.firebase.messaging.FirebaseMessaging
import com.pushed.android.auth.AuthManager
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.tasks.await
import android.content.Context
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manager for device registration with Firebase.
 * 
 * Handles:
 * - Registering Android devices with unique device IDs
 * - Storing FCM tokens for push notification delivery
 * - Updating device status and heartbeats
 */
@Singleton
class DeviceManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val firestore: FirebaseFirestore,
    private val messaging: FirebaseMessaging,
    private val authManager: AuthManager
) {

    private var cachedDeviceId: String? = null
    private var cachedFcmToken: String? = null

    /**
     * Get the unique device ID for this device.
     * Uses Android ID as a stable, unique identifier.
     */
    fun getDeviceId(): String {
        return cachedDeviceId ?: run {
            val androidId = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ANDROID_ID
            )
            cachedDeviceId = "android_$androidId"
            cachedDeviceId!!
        }
    }

    /**
     * Get the device name for display purposes.
     */
    fun getDeviceName(): String {
        val manufacturer = Build.MANUFACTURER.replaceFirstChar { it.uppercase() }
        val model = Build.MODEL
        return if (model.startsWith(manufacturer, ignoreCase = true)) {
            model
        } else {
            "$manufacturer $model"
        }
    }

    /**
     * Get the current FCM token for this device.
     */
    suspend fun getFcmToken(): String? {
        return try {
            cachedFcmToken ?: messaging.token.await().also {
                cachedFcmToken = it
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get FCM token", e)
            null
        }
    }

    /**
     * Register this device with Firebase for the current user.
     * 
     * Must be called after successful authentication.
     * 
     * @return Result indicating success or failure
     */
    suspend fun registerDevice(): Result<Unit> {
        val userId = authManager.currentUserId
            ?: return Result.failure(IllegalStateException("User must be authenticated"))

        val fcmToken = getFcmToken()
            ?: return Result.failure(IllegalStateException("Failed to get FCM token"))

        val deviceId = getDeviceId()
        val deviceName = getDeviceName()

        return try {
            val deviceData = hashMapOf(
                "type" to "android",
                "fcmToken" to fcmToken,
                "deviceName" to deviceName,
                "lastSeen" to FieldValue.serverTimestamp(),
                "createdAt" to FieldValue.serverTimestamp(),
                "appVersion" to getAppVersion(),
                "osVersion" to "Android ${Build.VERSION.RELEASE}",
                "sdkVersion" to Build.VERSION.SDK_INT
            )

            firestore
                .collection("users")
                .document(userId)
                .collection("devices")
                .document(deviceId)
                .set(deviceData, SetOptions.merge())
                .await()

            Log.i(TAG, "Device registered successfully: $deviceId for user $userId")
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register device", e)
            Result.failure(e)
        }
    }

    /**
     * Unregister this device from Firebase.
     * 
     * Called when user signs out or disables notification forwarding.
     */
    suspend fun unregisterDevice(): Result<Unit> {
        val userId = authManager.currentUserId
            ?: return Result.failure(IllegalStateException("User must be authenticated"))

        val deviceId = getDeviceId()

        return try {
            firestore
                .collection("users")
                .document(userId)
                .collection("devices")
                .document(deviceId)
                .delete()
                .await()

            Log.i(TAG, "Device unregistered: $deviceId")
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unregister device", e)
            Result.failure(e)
        }
    }

    /**
     * Update the FCM token for this device.
     * 
     * Called when FCM token is refreshed.
     */
    suspend fun updateFcmToken(newToken: String): Result<Unit> {
        cachedFcmToken = newToken

        val userId = authManager.currentUserId ?: return Result.success(Unit)

        val deviceId = getDeviceId()

        return try {
            firestore
                .collection("users")
                .document(userId)
                .collection("devices")
                .document(deviceId)
                .update(
                    mapOf(
                        "fcmToken" to newToken,
                        "lastSeen" to FieldValue.serverTimestamp()
                    )
                )
                .await()

            Log.i(TAG, "FCM token updated for device $deviceId")
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update FCM token", e)
            Result.failure(e)
        }
    }

    /**
     * Send a heartbeat to update the device's lastSeen timestamp.
     */
    suspend fun sendHeartbeat(): Result<Unit> {
        val userId = authManager.currentUserId ?: return Result.success(Unit)

        val deviceId = getDeviceId()

        return try {
            firestore
                .collection("users")
                .document(userId)
                .collection("devices")
                .document(deviceId)
                .update("lastSeen", FieldValue.serverTimestamp())
                .await()

            Log.d(TAG, "Heartbeat sent for device $deviceId")
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send heartbeat", e)
            Result.failure(e)
        }
    }

    private fun getAppVersion(): String {
        return try {
            val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
            packageInfo.versionName ?: "unknown"
        } catch (e: Exception) {
            "unknown"
        }
    }

    companion object {
        private const val TAG = "DeviceManager"
    }
}
