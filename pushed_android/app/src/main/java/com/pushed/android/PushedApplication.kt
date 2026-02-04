package com.pushed.android

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import dagger.hilt.android.HiltAndroidApp

/**
 * Main Application class for Pushed Android.
 * 
 * Initializes Hilt dependency injection and creates notification channels.
 */
@HiltAndroidApp
class PushedApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)

            // Foreground service channel (for persistent listener status)
            val serviceChannel = NotificationChannel(
                CHANNEL_SERVICE,
                "Listener Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when Pushed is actively listening for notifications"
                setShowBadge(false)
            }

            // Status updates channel
            val statusChannel = NotificationChannel(
                CHANNEL_STATUS,
                "Status Updates",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Connection status and sync updates"
            }

            notificationManager.createNotificationChannels(listOf(serviceChannel, statusChannel))
        }
    }

    companion object {
        const val CHANNEL_SERVICE = "pushed_service_channel"
        const val CHANNEL_STATUS = "pushed_status_channel"
    }
}
