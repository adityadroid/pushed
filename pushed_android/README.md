# Pushed Android

Android companion app for the Pushed notification bridging system.

## Overview

This app intercepts system notifications using `NotificationListenerService` and forwards them to the watchOS companion app. It acts as the **listener** in the notification bridge architecture.

## Architecture

```
pushed_android/app/src/main/java/com/pushed/android/
├── PushedApplication.kt           # Application class with Hilt
├── di/
│   └── AppModule.kt              # Hilt dependency injection
├── service/
│   ├── PushedNotificationListener.kt # Core notification listener
│   └── NotificationFilter.kt      # Filtering logic
├── data/
│   ├── model/
│   │   ├── PushedNotification.kt  # Shared contract implementation
│   │   └── Serializers.kt         # JSON serializers
│   ├── local/
│   │   ├── PushedDatabase.kt      # Room database
│   │   ├── NotificationDao.kt     # Data access object
│   │   └── Converters.kt          # Room type converters
│   ├── repository/
│   │   └── NotificationRepository.kt # Repository pattern
│   └── preferences/
│       └── UserPreferences.kt     # DataStore preferences
├── sync/
│   └── WatchSyncManager.kt        # Watch sync communication
└── ui/
    └── MainActivity.kt            # Main UI (to be implemented)
```

## Requirements

- Android API 26+ (Android 8.0 Oreo)
- Kotlin 1.9+
- Gradle 8.0+

## Key Components

### NotificationListenerService
The core component that intercepts all system notifications:
- Transforms notifications to shared contract format
- Filters based on user preferences
- Forwards to watch via sync manager

### Room Database
Local persistence for notifications:
- 7-day retention policy
- Sync state tracking
- Efficient querying

### DataStore Preferences
User settings for:
- Blocked apps
- Category filters
- Sync behavior
- Battery optimization

## Permissions

```xml
<!-- Required -->
<uses-permission android:name="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE" />

<!-- Android 13+ -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Foreground service -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
```

## Development Guidelines

See [AGENTS.md](../../AGENTS.md) for:
- Doze mode compliance
- Battery optimization
- Background processing best practices
- Testing requirements

## Building

```bash
# Build debug variant
./gradlew :pushed_android:assembleDemoDebug

# Run lint
./gradlew :pushed_android:spotlessApply

# Run tests
./gradlew :pushed_android:testDemoDebugUnitTest
```

## Setting Up Notification Access

1. Open Android Settings
2. Navigate to Apps > Special app access > Notification access
3. Enable "Pushed" in the list
4. Grant any additional permissions requested
