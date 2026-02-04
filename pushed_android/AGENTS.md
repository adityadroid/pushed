# AGENTS.md — Android (`pushed_android`)

> **Role:** Listener  
> **Description:** Intercepts system notifications via `NotificationListenerService`  
> Reference: [sample_android.md](../sample_android.md)

---

## Architecture

- **Single-Activity Architecture**: Use Jetpack Compose for all UI
- **MVVM + UDF**: ViewModels as state holders, expose UI state via `StateFlow`
- **Dependency Injection**: Use Hilt throughout
- **Repository Pattern**: Abstract data sources behind repositories

---

## Technology Stack

| Layer            | Technology                       |
| ---------------- | -------------------------------- |
| UI               | Jetpack Compose, Material 3      |
| State Management | ViewModel, Kotlin Flow           |
| DI               | Hilt                             |
| Navigation       | Jetpack Navigation Compose       |
| Local Storage    | Room, DataStore                  |
| Networking       | Retrofit, OkHttp                 |
| Background       | WorkManager, Foreground Services |

---

## NotificationListenerService Guidelines

**Implementation Helper:**
Refer to `NotificationListenerService` documentation. The service must:
1. Extend `NotificationListenerService`.
2. Handle `onNotificationPosted` to intercept and forward notifications.
3. Handle `onNotificationRemoved` to sync dismissals.

**Critical Requirements:**

1. **Permission Handling**
   - Request `BIND_NOTIFICATION_LISTENER_SERVICE` permission
   - Guide users to enable access via Settings
   - Gracefully handle permission revocation
   
2. **Service Lifecycle**
   - Use `onListenerConnected()` and `onListenerDisconnected()`
   - Persist service state for recovery
   - Implement proper cleanup in `onDestroy()`

---

## Background Processing & Battery Optimization

**Doze Mode Compliance:**
- ❌ NEVER: Schedule exact alarms for non-critical tasks
- ✅ ALWAYS: Use WorkManager with appropriate constraints (`CONNECTED`, `NOT_LOW` battery).

**Battery Optimization Rules:**
- Batch network requests.
- Use `WorkManager` for deferrable tasks.
- Respect battery saver mode.
- Minimize wake locks.

---

## Foreground Service Requirements

- Must show a persistent notification.
- Use `FOREGROUND_SERVICE_TYPE_SPECIAL_USE`.

---

## Permission Handling

**Required Permissions:**
- `BIND_NOTIFICATION_LISTENER_SERVICE`
- `POST_NOTIFICATIONS` (Android 13+)
- `FOREGROUND_SERVICE` & `FOREGROUND_SERVICE_SPECIAL_USE`
- `INTERNET`
- `RECEIVE_BOOT_COMPLETED`

Ensure runtime permission flows guide the user to System Settings when necessary.

---

## Build Commands

```bash
# Build debug variant
./gradlew :pushed_android:assembleDemoDebug

# Run linting
./gradlew :pushed_android:spotlessApply

# Run unit tests
./gradlew :pushed_android:testDemoDebugUnitTest

# Run instrumented tests
./gradlew :pushed_android:connectedDemoDebugAndroidTest
```

---

## Testing Guidelines

- Use `Robolectric` for unit tests.
- Use instrumented tests for service lifecycle verification.

---

## Kotlin Data Model

Data class `PushedNotification` must be `@Serializable` and match the shared contract schema.
See `PushedNotification.kt`.
