package com.pushed.android.data.preferences

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "user_preferences")

/**
 * User preferences for notification filtering and sync behavior.
 */
@Singleton
class UserPreferences @Inject constructor(
    @ApplicationContext private val context: Context
) {

    // Keys
    private object PreferenceKeys {
        val FORWARD_ONGOING = booleanPreferencesKey("forward_ongoing")
        val FORWARD_LOW_PRIORITY = booleanPreferencesKey("forward_low_priority")
        val FORWARD_SILENT = booleanPreferencesKey("forward_silent")
        val BLOCKED_PACKAGES = stringSetPreferencesKey("blocked_packages")
        val ENABLED_CATEGORIES = stringSetPreferencesKey("enabled_categories")
        val SYNC_ENABLED = booleanPreferencesKey("sync_enabled")
        val BATTERY_SAVER_RESPECT = booleanPreferencesKey("battery_saver_respect")
    }

    // Forward ongoing notifications (e.g., music players, timers)
    val forwardOngoingNotifications: Flow<Boolean> = context.dataStore.data.map { preferences ->
        preferences[PreferenceKeys.FORWARD_ONGOING] ?: false
    }

    suspend fun setForwardOngoingNotifications(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[PreferenceKeys.FORWARD_ONGOING] = enabled
        }
    }

    // Forward low priority notifications
    val forwardLowPriorityNotifications: Flow<Boolean> = context.dataStore.data.map { preferences ->
        preferences[PreferenceKeys.FORWARD_LOW_PRIORITY] ?: false
    }

    suspend fun setForwardLowPriorityNotifications(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[PreferenceKeys.FORWARD_LOW_PRIORITY] = enabled
        }
    }

    // Forward silent notifications
    val forwardSilentNotifications: Flow<Boolean> = context.dataStore.data.map { preferences ->
        preferences[PreferenceKeys.FORWARD_SILENT] ?: false
    }

    suspend fun setForwardSilentNotifications(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[PreferenceKeys.FORWARD_SILENT] = enabled
        }
    }

    // Blocked package names
    val blockedPackages: Flow<Set<String>> = context.dataStore.data.map { preferences ->
        preferences[PreferenceKeys.BLOCKED_PACKAGES] ?: emptySet()
    }

    suspend fun addBlockedPackage(packageName: String) {
        context.dataStore.edit { preferences ->
            val current = preferences[PreferenceKeys.BLOCKED_PACKAGES] ?: emptySet()
            preferences[PreferenceKeys.BLOCKED_PACKAGES] = current + packageName
        }
    }

    suspend fun removeBlockedPackage(packageName: String) {
        context.dataStore.edit { preferences ->
            val current = preferences[PreferenceKeys.BLOCKED_PACKAGES] ?: emptySet()
            preferences[PreferenceKeys.BLOCKED_PACKAGES] = current - packageName
        }
    }

    // Enabled categories (empty = all enabled)
    val enabledCategories: Flow<Set<String>> = context.dataStore.data.map { preferences ->
        preferences[PreferenceKeys.ENABLED_CATEGORIES] ?: emptySet()
    }

    suspend fun setEnabledCategories(categories: Set<String>) {
        context.dataStore.edit { preferences ->
            preferences[PreferenceKeys.ENABLED_CATEGORIES] = categories
        }
    }

    // Master sync toggle
    val syncEnabled: Flow<Boolean> = context.dataStore.data.map { preferences ->
        preferences[PreferenceKeys.SYNC_ENABLED] ?: true
    }

    suspend fun setSyncEnabled(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[PreferenceKeys.SYNC_ENABLED] = enabled
        }
    }

    // Respect battery saver mode
    val respectBatterySaver: Flow<Boolean> = context.dataStore.data.map { preferences ->
        preferences[PreferenceKeys.BATTERY_SAVER_RESPECT] ?: true
    }

    suspend fun setRespectBatterySaver(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[PreferenceKeys.BATTERY_SAVER_RESPECT] = enabled
        }
    }
}
