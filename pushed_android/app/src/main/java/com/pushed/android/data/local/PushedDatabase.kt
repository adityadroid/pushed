package com.pushed.android.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.pushed.android.data.model.PushedNotification

/**
 * Main Room database for Pushed Android app.
 */
@Database(
    entities = [PushedNotification::class],
    version = 1,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class PushedDatabase : RoomDatabase() {
    abstract fun notificationDao(): NotificationDao

    companion object {
        const val DATABASE_NAME = "pushed_database"
    }
}
