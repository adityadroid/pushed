# AGENTS.md — Pushed Notification Bridge Monorepo

This document establishes the governance rules, coding standards, and synchronization protocols for AI agents working on the **Pushed** cross-platform notification bridging system.

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Common Standards](#common-standards)
3. [Android Specifics (pushed_android)](#android-specifics-pushed_android)
4. [Firebase Specifics (pushed_firebase)](#firebase-specifics-pushed_firebase)
5. [watchOS Specifics (pushed_watch)](#watchos-specifics-pushed_watch)
6. [Shared Contract & Data Models](#shared-contract--data-models)
7. [Synchronization Protocols](#synchronization-protocols)
8. [Testing Guidelines](#testing-guidelines)
9. [Security & Privacy](#security--privacy)
10. [Traceability & Execution Logging](#traceability--execution-logging)
11. [AGENTS.md Governance](#agentsmd-governance)
12. [Operational Protocols](#operational-protocols)

---

## Project Overview

**Pushed** is a notification bridging system consisting of:

| App               | Platform     | Role             | Description                                                       |
| ----------------- | ------------ | ---------------- | ----------------------------------------------------------------- |
| `pushed_android`  | Android      | **Listener**     | Intercepts system notifications via `NotificationListenerService` |
| `pushed_firebase` | Firebase/GCP | **Orchestrator** | Middleware for auth, data sync, and push notification dispatch    |
| `pushed_watch`    | watchOS      | **Renderer**     | Receives and displays forwarded notifications                     |

### Separation of Concerns

```
┌─────────────────────┐     ┌─────────────────────────┐     ┌─────────────────────┐
│   pushed_android    │     │     pushed_firebase     │     │    pushed_watch     │
│   ───────────────   │     │    ───────────────      │     │   ───────────────   │
│   • Intercept       │     │   • Authenticate        │     │   • Receive         │
│   • Filter          │────►│   • Queue & Store       │────►│   • Display         │
│   • Transform       │     │   • Dispatch via FCM    │     │   • Manage          │
│   • Write to DB     │     │   • Device Registry     │     │   • Archive         │
└─────────────────────┘     └─────────────────────────┘     └─────────────────────┘
        LISTENER                   ORCHESTRATOR                    RENDERER

                            Shared Contract (JSON Schema)
```

### Data Flow

```
1. Android device receives notification
2. pushed_android transforms and writes to Firestore
3. pushed_firebase Cloud Function triggers on write
4. Function fetches registered watchOS devices
5. FCM dispatches push notification to Apple Watch
6. pushed_watch displays notification via APNs → FCM bridge
```

---

## Common Standards

### Versioning

- **Semantic Versioning**: All releases follow `MAJOR.MINOR.PATCH` format
  - `MAJOR`: Breaking changes to the shared contract
  - `MINOR`: New features, backward-compatible
  - `PATCH`: Bug fixes, no API changes
  
- **Contract Version**: The shared notification payload schema includes a `schemaVersion` field
  - Both apps MUST validate incoming payloads against expected schema versions
  - Maintain backward compatibility for at least 2 minor versions

### Commit Message Format

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style (formatting, not logic)
- `refactor`: Code restructure without behavior change
- `perf`: Performance improvement
- `test`: Test additions/modifications
- `chore`: Build, CI, tooling changes

**Scopes:**
- `android`: Changes to `pushed_android`
- `firebase`: Changes to `pushed_firebase`
- `watch`: Changes to `pushed_watch`
- `contract`: Changes to shared data models
- `infra`: Infrastructure/CI changes

**Examples:**
```bash
feat(android): add notification grouping support
fix(watch): resolve memory leak in notification list
docs(contract): update payload schema documentation
refactor(android): migrate to Kotlin Coroutines for async ops
```

### Branch Naming

```
<type>/<scope>-<short-description>

# Examples:
feat/android-notification-filtering
fix/watch-memory-leak
docs/contract-schema-v2
```

### Code Review Requirements

- All PRs require at least **1 approval** before merging
- PRs modifying the shared contract require **approval from both platform leads**
- Automated tests must pass before merge
- No direct commits to `main` branch

---

## Android Specifics (`pushed_android`)

> Reference: [sample_android.md](./sample_android.md)

### Architecture

- **Single-Activity Architecture**: Use Jetpack Compose for all UI
- **MVVM + UDF**: ViewModels as state holders, expose UI state via `StateFlow`
- **Dependency Injection**: Use Hilt throughout
- **Repository Pattern**: Abstract data sources behind repositories

### Technology Stack

| Layer            | Technology                       |
| ---------------- | -------------------------------- |
| UI               | Jetpack Compose, Material 3      |
| State Management | ViewModel, Kotlin Flow           |
| DI               | Hilt                             |
| Navigation       | Jetpack Navigation Compose       |
| Local Storage    | Room, DataStore                  |
| Networking       | Retrofit, OkHttp                 |
| Background       | WorkManager, Foreground Services |

### NotificationListenerService Guidelines

```kotlin
// REQUIRED: Extend NotificationListenerService
class PushedNotificationListener : NotificationListenerService() {
    
    // MUST handle notification posted
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        // Extract notification data
        // Transform to shared contract format
        // Forward to watchOS
    }
    
    // MUST handle notification removed
    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // Notify watchOS of dismissal
    }
}
```

**Critical Requirements:**

1. **Permission Handling**
   - Request `BIND_NOTIFICATION_LISTENER_SERVICE` permission
   - Guide users to enable access via Settings
   - Gracefully handle permission revocation
   
2. **Service Lifecycle**
   - Use `onListenerConnected()` and `onListenerDisconnected()`
   - Persist service state for recovery
   - Implement proper cleanup in `onDestroy()`

### Background Processing & Battery Optimization

**Doze Mode Compliance:**

```kotlin
// ❌ NEVER: Schedule exact alarms for non-critical tasks
// ✅ ALWAYS: Use WorkManager with appropriate constraints

val notificationSyncWork = OneTimeWorkRequestBuilder<NotificationSyncWorker>()
    .setConstraints(
        Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .setRequiresBatteryNotLow(true)
            .build()
    )
    .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 1, TimeUnit.MINUTES)
    .build()
```

**Battery Optimization Rules:**

- Batch network requests when possible
- Use `JobScheduler` or `WorkManager` for deferrable tasks
- Respect battery saver mode — check `PowerManager.isPowerSaveMode()`
- Use efficient serialization (prefer Protobuf over JSON for high-frequency data)
- Minimize wake locks; release immediately after use

### Foreground Service Requirements

```kotlin
// For persistent notification listener
val notification = NotificationCompat.Builder(this, CHANNEL_ID)
    .setContentTitle("Pushed Active")
    .setContentText("Listening for notifications")
    .setSmallIcon(R.drawable.ic_notification)
    .setOngoing(true)
    .setCategory(NotificationCompat.CATEGORY_SERVICE)
    .setPriority(NotificationCompat.PRIORITY_LOW)
    .build()

startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
```

### Permission Handling

```kotlin
// Required permissions in AndroidManifest.xml
<uses-permission android:name="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" /> <!-- Android 13+ -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

// Runtime permission flow
suspend fun checkAndRequestPermissions(): PermissionState {
    // 1. Check notification listener access
    // 2. Request POST_NOTIFICATIONS for Android 13+
    // 3. Check battery optimization exemption
    // 4. Return comprehensive permission state
}
```

### Build Commands

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

## Firebase Specifics (`pushed_firebase`)

> Reference: [pushed_firebase/README.md](./pushed_firebase/README.md)

### Role & Responsibilities

`pushed_firebase` is the **middleware orchestrator** that bridges Android and watchOS platforms:

| Function            | Description                                                   |
| ------------------- | ------------------------------------------------------------- |
| **Authentication**  | Shared Firebase Auth identity across platforms (Google/Email) |
| **Data Storage**    | Firestore database for device registry and notification queue |
| **Push Dispatch**   | Cloud Functions trigger FCM notifications to watchOS          |
| **Device Registry** | Tracks registered Android sender and watchOS receiver devices |

### Technology Stack

| Layer          | Technology                     |
| -------------- | ------------------------------ |
| Runtime        | Node.js 20+                    |
| Language       | TypeScript (strict mode)       |
| Functions      | Cloud Functions v2 (2nd gen)   |
| Database       | Cloud Firestore                |
| Authentication | Firebase Auth                  |
| Messaging      | Firebase Cloud Messaging (FCM) |

### Project Structure

```
pushed_firebase/
├── firebase.json           # Firebase configuration
├── firestore.rules         # Security rules for Firestore
├── firestore.indexes.json  # Composite indexes
├── .firebaserc             # Project alias config
└── functions/
    ├── package.json        # Node.js dependencies
    ├── tsconfig.json       # TypeScript configuration
    └── src/
        ├── index.ts        # Main Cloud Functions entry
        ├── notifications.ts # Notification dispatching logic
        └── types.ts        # TypeScript type definitions
```

### Cloud Functions

#### Firestore Triggers

| Function                | Trigger                                                | Description                                      |
| ----------------------- | ------------------------------------------------------ | ------------------------------------------------ |
| `onNotificationCreated` | `users/{userId}/notifications/{notificationId}` create | Dispatches FCM to all registered watchOS devices |
| `onNotificationDeleted` | `users/{userId}/notifications/{notificationId}` delete | Cleanup handler (optional)                       |

#### Callable Functions

| Function               | Purpose                                        |
| ---------------------- | ---------------------------------------------- |
| `registerDevice`       | Register Android/watchOS device with FCM token |
| `unregisterDevice`     | Remove device from registry                    |
| `updateDeviceToken`    | Refresh FCM token after rotation               |
| `deviceHeartbeat`      | Update device lastSeen timestamp               |
| `getRegisteredDevices` | List all devices for current user              |

### Firestore Schema

```
users/
└── {userId}/
    ├── devices/{deviceId}
    │   ├── type: "android" | "watchos"
    │   ├── fcmToken: string
    │   ├── deviceName: string
    │   ├── lastSeen: timestamp
    │   └── createdAt: timestamp
    │
    └── notifications/{notificationId}
        ├── id: string (UUID)
        ├── schemaVersion: string
        ├── timestamp: timestamp
        ├── title: string
        ├── body: string?
        ├── packageName: string
        ├── appName: string?
        ├── category: string
        ├── priority: string
        ├── sourceDeviceId: string
        ├── createdAt: timestamp
        └── dispatchedAt: timestamp (added by function)
```

### Security Rules

```javascript
// Key security constraints:
// 1. All operations require authentication
// 2. Users can only access their own data (user-isolated)
// 3. Device FCM tokens are protected
// 4. Notification validation enforced

match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
  
  match /devices/{deviceId} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
  
  match /notifications/{notificationId} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
    // Validates required fields and schema version
  }
}
```

### Cloud Function Guidelines

```typescript
// ALWAYS: Use v2 Cloud Functions syntax
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";

// ALWAYS: Specify region and resource limits
export const onNotificationCreated = onDocumentCreated(
    {
        document: "users/{userId}/notifications/{notificationId}",
        region: "us-central1",
        memory: "256MiB",
        timeoutSeconds: 60,
    },
    async (event) => { /* ... */ }
);

// ALWAYS: Validate authentication in callable functions
export const registerDevice = onCall(
    { region: "us-central1" },
    async (request) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "Authentication required");
        }
        // ...
    }
);
```

### Error Handling

```typescript
// ✅ ALWAYS: Log errors with context
logger.error("Error dispatching notification", {
    error,
    notificationId,
    userId,
});

// ✅ ALWAYS: Update document with error status
await docRef.update({
    dispatchError: error.message,
    dispatchedAt: admin.firestore.FieldValue.serverTimestamp(),
});

// ✅ ALWAYS: Clean up invalid FCM tokens
// When sendToDevice returns messaging/registration-token-not-registered
await deviceRef.delete();
```

### Build Commands

```bash
# Navigate to functions directory
cd pushed_firebase/functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Run linting
npm run lint

# Deploy all Firebase resources
firebase deploy

# Deploy only functions
firebase deploy --only functions

# Deploy only Firestore rules
firebase deploy --only firestore:rules

# Start local emulators
firebase emulators:start

# View function logs
firebase functions:log
```

### Environment & Configuration

```bash
# Required Firebase services:
# - Authentication (Google & Email/Password)
# - Cloud Firestore
# - Cloud Functions
# - Cloud Messaging

# For APNs (watchOS push):
# 1. Generate APNs Authentication Key in Apple Developer Console
# 2. Upload key to Firebase Console → Project Settings → Cloud Messaging
```

---

## watchOS Specifics (`pushed_watch`)

> Reference: [sample_ios.md](./sample_ios.md)

### Core Requirements

- **Target**: watchOS 11.0+
- **Swift Version**: Swift 6.2+
- **UI Framework**: SwiftUI with `@Observable` for state management
- **Concurrency**: Modern Swift concurrency (`async`/`await`, `Actor`)

### Technology Constraints

| ✅ Allowed             | ❌ Prohibited           |
| --------------------- | ---------------------- |
| SwiftUI               | WatchKit (legacy)      |
| `@Observable` classes | `ObservableObject`     |
| `NavigationStack`     | `NavigationView`       |
| Swift Concurrency     | Grand Central Dispatch |
| `foregroundStyle()`   | `foregroundColor()`    |

### SwiftUI Lifecycle Guidelines

```swift
// ALWAYS: Mark @Observable classes with @MainActor
@MainActor
@Observable
final class NotificationViewModel {
    var notifications: [PushedNotification] = []
    var isLoading = false
    
    func fetchNotifications() async {
        isLoading = true
        // Fetch logic
        isLoading = false
    }
}

// PREFER: Separate view structs over computed properties
struct NotificationRow: View {
    let notification: PushedNotification
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(notification.title)
                .bold()
            Text(notification.body)
                .foregroundStyle(.secondary)
        }
    }
}
```

### Complications Support

```swift
// Provide timeline entries for complications
struct NotificationComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> NotificationEntry {
        NotificationEntry(date: Date(), count: 0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NotificationEntry) -> Void) {
        completion(NotificationEntry(date: Date(), count: 3))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NotificationEntry>) -> Void) {
        // Generate timeline with notification counts
    }
}
```

### Efficient Networking on Wearable Hardware

**Critical Power Constraints:**

```swift
// ✅ ALWAYS: Batch requests, minimize frequency
// ✅ ALWAYS: Use background URLSession for non-urgent sync
// ✅ ALWAYS: Compress payloads
// ❌ NEVER: Poll frequently; use push notifications instead

@MainActor
@Observable
final class NotificationSyncService {
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.background(
            withIdentifier: "com.pushed.sync"
        )
        config.isDiscretionary = true // Let system optimize timing
        config.sessionSendsLaunchEvents = true
        self.session = URLSession(configuration: config)
    }
    
    func sync() async throws {
        // Use WatchConnectivity for iPhone-Watch communication
        // when iPhone is reachable
    }
}
```

**WatchConnectivity Best Practices:**

```swift
// Prefer application context for state synchronization
// Use transferUserInfo for queued, guaranteed delivery
// Use sendMessage only when Watch app is active and reachable

class ConnectivityManager: NSObject, WCSessionDelegate {
    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        // Handle incoming notification data
        // Parse using shared contract
    }
}
```

### Navigation & Layout

```swift
// ALWAYS: Use NavigationStack with navigationDestination
NavigationStack {
    List(notifications) { notification in
        NavigationLink(value: notification) {
            NotificationRow(notification: notification)
        }
    }
    .navigationDestination(for: PushedNotification.self) { notification in
        NotificationDetailView(notification: notification)
    }
}

// AVOID: GeometryReader when alternatives exist
// PREFER: containerRelativeFrame() for responsive sizing
```

### Build Commands

```bash
# Build for watchOS Simulator
xcodebuild -project pushed_watch/pushed_watch.xcodeproj \
    -scheme pushed_watch \
    -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)'

# Run tests
xcodebuild test -project pushed_watch/pushed_watch.xcodeproj \
    -scheme pushed_watch \
    -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)'

# SwiftLint (if installed)
swiftlint --config .swiftlint.yml
```

---

## Shared Contract & Data Models

### Notification Payload Schema (v1.0.0)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "PushedNotification",
  "type": "object",
  "required": ["id", "schemaVersion", "timestamp", "title", "packageName"],
  "properties": {
    "id": {
      "type": "string",
      "format": "uuid",
      "description": "Unique identifier for the notification"
    },
    "schemaVersion": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$",
      "description": "Semantic version of the payload schema"
    },
    "timestamp": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp when notification was received"
    },
    "title": {
      "type": "string",
      "description": "Notification title"
    },
    "body": {
      "type": "string",
      "description": "Notification body text"
    },
    "packageName": {
      "type": "string",
      "description": "Android package name or iOS bundle identifier"
    },
    "appName": {
      "type": "string",
      "description": "Human-readable application name"
    },
    "category": {
      "type": "string",
      "enum": ["message", "email", "social", "news", "promo", "reminder", "call", "other"],
      "description": "Notification category for filtering"
    },
    "priority": {
      "type": "string",
      "enum": ["min", "low", "default", "high", "max"],
      "description": "Notification priority level"
    },
    "actions": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "label"],
        "properties": {
          "id": { "type": "string" },
          "label": { "type": "string" },
          "isDestructive": { "type": "boolean" }
        }
      },
      "description": "Available actions for the notification"
    },
    "groupKey": {
      "type": "string",
      "description": "Key for grouping related notifications"
    },
    "isOngoing": {
      "type": "boolean",
      "description": "Whether this is an ongoing/persistent notification"
    },
    "iconData": {
      "type": "string",
      "contentEncoding": "base64",
      "description": "Base64-encoded app icon (optional, max 10KB)"
    }
  }
}
```

### Platform-Specific Implementations

**Android (Kotlin):**
```kotlin
// contract/src/main/kotlin/com/pushed/contract/PushedNotification.kt
@Serializable
data class PushedNotification(
    val id: String,
    val schemaVersion: String = "1.0.0",
    val timestamp: Instant,
    val title: String,
    val body: String? = null,
    val packageName: String,
    val appName: String? = null,
    val category: NotificationCategory = NotificationCategory.OTHER,
    val priority: NotificationPriority = NotificationPriority.DEFAULT,
    val actions: List<NotificationAction> = emptyList(),
    val groupKey: String? = null,
    val isOngoing: Boolean = false,
    val iconData: String? = null
)
```

**watchOS (Swift):**
```swift
// Contract/Sources/PushedNotification.swift
struct PushedNotification: Codable, Identifiable, Hashable {
    let id: UUID
    let schemaVersion: String
    let timestamp: Date
    let title: String
    let body: String?
    let packageName: String
    let appName: String?
    let category: NotificationCategory
    let priority: NotificationPriority
    let actions: [NotificationAction]
    let groupKey: String?
    let isOngoing: Bool
    let iconData: String?
}
```

---

## Synchronization Protocols

### Communication Channels

| Channel                                 | Use Case                  | Priority |
| --------------------------------------- | ------------------------- | -------- |
| WatchConnectivity (Application Context) | Latest state sync         | High     |
| WatchConnectivity (User Info Transfer)  | Guaranteed delivery queue | Medium   |
| Push Notifications (APNs)               | Real-time alerts          | High     |
| Background Fetch                        | Periodic sync             | Low      |

### Conflict Resolution

1. **Timestamp Authority**: Server/Android timestamp is authoritative
2. **Last-Write-Wins**: For notification state (read/unread)
3. **Merge Strategy**: For notification list — union of all notifications

### Offline Handling

- Both apps MUST cache notifications locally
- Android: Room database with 7-day retention
- watchOS: SwiftData with automatic sync to iPhone
- On reconnect, perform delta sync based on last sync timestamp

---

## Testing Guidelines

### Android Testing

```kotlin
// Unit tests for business logic
@Test
fun `notification transformer handles empty body`() {
    val sbn = mockStatusBarNotification(title = "Test", body = null)
    val result = transformer.transform(sbn)
    assertThat(result.body).isNull()
}

// Integration tests for service
@Test
fun `listener service forwards notifications correctly`() {
    // Use Robolectric or instrumented tests
}
```

### watchOS Testing

```swift
// Unit tests with Swift Testing
@Test func notificationDecoding() throws {
    let json = """
    {"id":"123","schemaVersion":"1.0.0","timestamp":"2024-01-01T00:00:00Z","title":"Test","packageName":"com.test"}
    """
    let notification = try JSONDecoder().decode(PushedNotification.self, from: Data(json.utf8))
    #expect(notification.title == "Test")
}

// View model tests
@Test func viewModelLoadsNotifications() async {
    let viewModel = NotificationViewModel()
    await viewModel.fetchNotifications()
    #expect(!viewModel.notifications.isEmpty)
}
```

---

## Security & Privacy

### Data Protection

- **Encryption**: All network traffic MUST use TLS 1.3+
- **Local Storage**: Use encrypted storage (Android EncryptedSharedPreferences, iOS Keychain)
- **Sensitive Data**: Never log full notification content in production
- **Icon Data**: Strip EXIF data, limit size to 10KB

### Permission Transparency

- Clearly explain why notification access is needed
- Provide granular control over which apps to monitor
- Allow users to pause/disable bridging at any time
- Respect "Do Not Disturb" modes on both platforms

### Data Retention

- Notifications auto-delete after 7 days
- Users can manually clear all data
- No server-side storage of notification content (direct P2P only)

---

## Traceability & Execution Logging

> **Effective Date:** 2026-02-04  
> **Version:** 1.0.0

Every significant task performed by an AI agent MUST be documented in the `/plans` directory at the root of this repository. This ensures continuity across agent sessions, enables knowledge transfer, and maintains a complete audit trail of changes.

### Plan Directory Structure

```
plans/
├── template.md                              # Standard template for all plans
├── YYYY-MM-DD-task-name.md                 # Individual plan documents
└── ...
```

### Required Documentation

For every significant task, create a Markdown file following the naming convention:

```
plans/YYYY-MM-DD-task-name.md
```

**Example:** `plans/2026-02-04-implement-notification-listener.md`

Each plan document MUST contain the following sections:

#### 1. Task Metadata

| Field             | Description                                         |
| ----------------- | --------------------------------------------------- |
| **Task Name**     | Brief descriptive name                              |
| **Date**          | YYYY-MM-DD format                                   |
| **Agent Session** | Session identifier (if available)                   |
| **Status**        | 🟡 Planning / 🔵 In Progress / 🟢 Completed / 🔴 Failed |
| **User Prompt**   | The exact instruction provided by the user          |

#### 2. Proposed Strategy

- **Objective**: What this task aims to achieve
- **Architectural Overview**: High-level approach and design decisions
- **Implementation Steps**: Ordered list of planned actions
- **Dependencies**: Prerequisites and external requirements

#### 3. Execution Log

- **Files Modified**: Table of created/modified/deleted files with descriptions
- **New Dependencies**: Any libraries, packages, or services added
- **Boilerplate Generated**: Templates and scaffolding created
- **Commands Executed**: Significant commands run during execution

#### 4. Outcome & Validation

- **Final Result**: Summary of what was accomplished
- **Verification Steps**: How to verify the implementation works
- **Known Limitations**: Edge cases, incomplete functionality, or technical debt
- **Test Results**: Status of unit tests, builds, and manual testing

#### 5. State Update

- **Global Context Changes**: Changes that affect the entire project
- **Breaking Changes**: Schema or API changes requiring migration
- **Cross-App Impact**: Effects on other applications in the monorepo
- **Configuration Changes**: Environment variables, config files, or settings

### Directive: Atomicity

Each plan document MUST cover **one logical feature or task**. Examples of atomic tasks:

✅ **Good (Atomic):**
- "Implement Android Notification Listener"
- "Add SwiftUI Notification Detail View"
- "Update Contract Schema to v1.1.0"
- "Fix Memory Leak in Watch Sync Service"

❌ **Bad (Non-Atomic):**
- "Implement entire notification system" (too broad)
- "Various fixes and improvements" (not specific)
- "Update all apps" (multiple concerns)

### Directive: Cross-App Impact & Breaking Changes

When a change in one component affects another, the plan MUST explicitly flag this:

```markdown
### Breaking Changes

> ⚠️ **Breaking Change Alert**: [Description]

| Component Affected | Change        | Migration Path   |
| ------------------ | ------------- | ---------------- |
| `pushed_android`   | [Description] | [How to migrate] |
| `pushed_watch`     | [Description] | [How to migrate] |
| `contract`         | [Description] | [How to migrate] |
```

**Examples of breaking changes:**
- Modifying the notification payload schema
- Changing required fields in the contract
- Altering the communication protocol between apps
- Removing or renaming public APIs

### Directive: Persistence & Continuity

Before starting any new work, agents MUST:

1. **Check the `/plans` directory** for existing plans related to the task
2. **Review recent plans** to understand current project state
3. **Reference prior plans** when building on previous work
4. **Update existing plans** if continuing incomplete work

```bash
# Before starting work, review existing plans
ls -la plans/
cat plans/YYYY-MM-DD-related-task.md
```

### When to Create a Plan

| Scenario                           | Plan Required?        |
| ---------------------------------- | --------------------- |
| New feature implementation         | ✅ Yes                 |
| Significant refactoring            | ✅ Yes                 |
| Schema or API changes              | ✅ Yes                 |
| Bug fix with multiple file changes | ✅ Yes                 |
| Simple typo fix                    | ❌ No                  |
| Updating dependencies              | ⚠️ Only if breaking    |
| Documentation updates              | ⚠️ Only if significant |

### Template Location

Use the template at `plans/template.md` as the starting point for all plan documents.

### Enforcement

- All PRs involving significant changes SHOULD reference their plan document
- Code reviewers MAY request a plan document for undocumented changes
- Plans serve as permanent documentation and should be maintained

---

## AGENTS.md Governance

> **Effective Date:** 2026-02-04  
> **Version:** 1.0.0

This section establishes the rules for maintaining the `AGENTS.md` file itself. The goal is to ensure this document remains an accurate, authoritative source of truth for the repository's architecture and development standards.

### Mandatory Synchronization Rule

> ⚠️ **CRITICAL**: Whenever the repository undergoes a **major change**, the `AGENTS.md` file **MUST** be updated to reflect that change.

**Major changes include, but are not limited to:**

| Change Type              | Example                                             | Action Required                                                    |
| ------------------------ | --------------------------------------------------- | ------------------------------------------------------------------ |
| **New Component**        | Adding `pushed_firebase` as middleware              | Add new specifics section, update architecture diagram, update ToC |
| **Architecture Shift**   | Changing from P2P to cloud-orchestrated             | Update Project Overview, architecture diagrams, data flow          |
| **Technology Migration** | SwiftUI → UIKit, Hilt → Koin                        | Update technology stack tables, code guidelines                    |
| **Protocol Change**      | New authentication method, different sync mechanism | Update Synchronization Protocols, Security sections                |
| **Schema Evolution**     | Breaking changes to notification payload            | Update Shared Contract section, flag breaking change               |
| **Platform Addition**    | iOS companion app, web dashboard                    | Add new platform section with full specifics                       |

### When to Update AGENTS.md

| Scenario                                      | Update Required?                           |
| --------------------------------------------- | ------------------------------------------ |
| Adding a new app/component to the monorepo    | ✅ **Yes** — add full specifics section     |
| Changing core architecture patterns           | ✅ **Yes** — update diagrams and guidelines |
| Introducing new technology or framework       | ✅ **Yes** — update stack tables            |
| Modifying the shared contract schema          | ✅ **Yes** — update contract section        |
| Adding new build commands or workflows        | ✅ **Yes** — add to relevant section        |
| Fixing a bug                                  | ❌ No                                       |
| Minor refactoring without architecture change | ❌ No                                       |
| Updating documentation typos                  | ❌ No (unless in AGENTS.md itself)          |

### Update Procedure

When a major change occurs:

1. **Create a plan document** in `/plans` for the proposed changes
2. **Justify the change** with clear rationale
3. **Consider cross-platform impact** — rules often affect multiple apps
4. **Maintain backward compatibility** when possible

### Versioning Rules

AGENTS.md follows semantic versioning for its own changes:

| Change Type       | Version Bump          | Examples                                                  |
| ----------------- | --------------------- | --------------------------------------------------------- |
| **Major** (X.0.0) | Breaking rule changes | Removing a required section, changing mandatory protocols |
| **Minor** (x.Y.0) | New rules or sections | Adding new governance rules, new platform support         |
| **Patch** (x.y.Z) | Clarifications, fixes | Typo fixes, formatting improvements, examples             |

### Change Log Requirements

Every update to AGENTS.md MUST:

1. **Increment the version** appropriately in the Change Log
2. **Add a dated entry** describing the change
3. **Reference the plan document** if applicable

```markdown
| Version | Date       | Changes                   |
| ------- | ---------- | ------------------------- |
| X.Y.Z   | YYYY-MM-DD | Description of the change |
```

### Adding New Platform/Component Sections

When adding support for a new platform (e.g., `pushed_firebase`):

1. **Add to Table of Contents** — Insert in appropriate order
2. **Update Project Overview** — Add to the architecture diagram and app table
3. **Add Commit Scope** — Register new scope in Common Standards
4. **Create Full Section** — Document technology stack, guidelines, and commands
5. **Update Breaking Changes Template** — Include new component in cross-app impact tables

### Section Template for New Platforms

```markdown
## [Platform] Specifics (`component_name`)

> Reference: [sample_platform.md](./sample_platform.md)

### Architecture
[Describe the architecture patterns and structure]

### Technology Stack
| Layer | Technology |
| ----- | ---------- |
| ...   | ...        |

### Guidelines
[Platform-specific coding guidelines]

### Build Commands
```bash
# Build and test commands
```
```

### Prohibited Changes

The following changes to AGENTS.md are **NOT ALLOWED** without explicit human approval:

- ❌ Removing existing governance rules entirely
- ❌ Weakening security or privacy requirements
- ❌ Changing versioning policies
- ❌ Modifying the contract schema without coordination
- ❌ Removing mandatory plan documentation requirements

### Allowed Changes by Agents

Agents MAY make the following changes without special approval:

- ✅ Adding new platform/component sections
- ✅ Clarifying existing rules with examples
- ✅ Fixing typos and formatting
- ✅ Adding new best practices (non-breaking)
- ✅ Updating technology stack recommendations
- ✅ Expanding the Change Log

### Conflict Resolution

If two rules in AGENTS.md conflict:

1. **More specific rule wins** over general rules
2. **Security rules** take precedence over convenience
3. **Contract integrity** takes precedence over single-platform needs
4. When in doubt, **create a plan document** to propose resolution

### Review Checklist

Before committing changes to AGENTS.md:

- [ ] Version number incremented appropriately
- [ ] Change Log updated with description
- [ ] Table of Contents reflects any new sections
- [ ] Cross-references and links are valid
- [ ] No breaking changes without migration path
- [ ] Plan document created (if significant change)

---

## Operational Protocols

> **Effective Date:** 2026-02-04  
> **Version:** 1.0.0

This section establishes the autonomous behaviors and operational protocols for AI agents executing tasks in this repository. These protocols enable efficient, self-directed task completion while maintaining quality and traceability.

### Task Finalization

AI agents are granted autonomy over the complete task lifecycle, from execution to version control. The following behaviors are **mandatory** upon task execution:

---

#### 1. Completion Judgment

> **Directive:** Agents MUST independently determine when a task is complete based on objective criteria.

**Completion Criteria:**

| Criterion                  | Requirement                                                           |
| -------------------------- | --------------------------------------------------------------------- |
| **Requirements Met**       | All aspects of the initial user request have been addressed           |
| **Build Success**          | The project compiles/builds without errors                            |
| **Tests Passing**          | All relevant unit tests and integration tests pass                    |
| **Linting Clean**          | No blocking lint errors (warnings acceptable if justified)            |
| **Documentation Updated**  | Relevant docs (AGENTS.md, README, etc.) reflect the changes           |
| **Plan Document Complete** | Execution log and outcome sections filled in (per Traceability rules) |

**Decision Authority:**

- ✅ Agents **SHALL NOT** wait for explicit human "looks good" confirmation when all technical criteria are satisfied
- ✅ Agents **SHALL** proceed to the commit phase immediately upon meeting all criteria
- ✅ Agents **MAY** request clarification only if the initial requirements are genuinely ambiguous

**Completion Checklist:**

```
☐ Initial requirements addressed
☐ Build succeeds (no compilation errors)
☐ All relevant tests pass
☐ No blocking lint errors
☐ Plan document updated (if applicable)
☐ Ready for commit
```

---

#### 2. Automated Commits

> **Directive:** Upon determining task completion, agents MUST automatically stage and commit all changes.

**Commit Procedure:**

1. **Stage Changes**
   ```bash
   git add -A
   ```

2. **Verify Staged Files**
   ```bash
   git status
   ```
   - Confirm only intended files are staged
   - Ensure no sensitive files (secrets, credentials) are included
   - Verify `.gitignore` is respected

3. **Execute Commit**
   ```bash
   git commit -m "<type>(<scope>): <description>"
   ```

**Automatic Commit Conditions:**

| Condition              | Behavior                                                        |
| ---------------------- | --------------------------------------------------------------- |
| All criteria met       | ✅ Commit immediately                                            |
| Tests failing          | ❌ Do NOT commit; fix issues first                               |
| Build errors           | ❌ Do NOT commit; resolve errors first                           |
| Uncommitted plan doc   | ⚠️ Include plan document in the commit                           |
| Partial implementation | ⚠️ Only commit if user explicitly requested incremental progress |

**Files to Always Include:**

- Modified source code files
- Updated test files
- Plan documents (in `/plans` directory)
- Updated documentation (AGENTS.md, README.md, etc.)
- Configuration changes

---

#### 3. Commit Message Format

> **Directive:** All commit messages MUST follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

**Format:**

```
<type>(<scope>): <description>
```

**Types** (as defined in Common Standards):

| Type       | Purpose                                  |
| ---------- | ---------------------------------------- |
| `feat`     | New feature                              |
| `fix`      | Bug fix                                  |
| `docs`     | Documentation only                       |
| `style`    | Code style (formatting, not logic)       |
| `refactor` | Code restructure without behavior change |
| `perf`     | Performance improvement                  |
| `test`     | Test additions/modifications             |
| `chore`    | Build, CI, tooling changes               |

**Scopes** (as defined in Common Standards):

| Scope      | Component                    |
| ---------- | ---------------------------- |
| `android`  | `pushed_android` changes     |
| `firebase` | `pushed_firebase` changes    |
| `watch`    | `pushed_watch` changes       |
| `contract` | Shared data model changes    |
| `infra`    | Infrastructure/CI changes    |
| `agents`   | AGENTS.md governance changes |

**Examples:**

```bash
# Feature additions
feat(android): implement notification filtering by app category
feat(watch): add swipe-to-dismiss gesture for notifications
feat(firebase): add device heartbeat Cloud Function

# Bug fixes
fix(android): resolve memory leak in NotificationListenerService
fix(watch): correct timestamp parsing for ISO 8601 dates
fix(firebase): handle expired FCM tokens gracefully

# Documentation
docs(agents): add Operational Protocols section for task finalization
docs(contract): update notification payload schema examples

# Refactoring
refactor(android): migrate to Kotlin Coroutines for async operations
```

**Message Guidelines:**

- ✅ Use imperative mood ("add" not "added")
- ✅ Keep description under 72 characters
- ✅ Be specific and descriptive
- ❌ Avoid vague messages like "fix bug" or "update code"
- ❌ Do not include issue/ticket numbers unless referencing external trackers

---

#### 4. Post-Commit Verification

> **Directive:** After every commit, agents MUST provide a verification summary to the user.

**Required Summary Format:**

```markdown
## ✅ Task Completed

**Summary:** [Brief description of what was accomplished]

**Commit:** `<short-hash>` — `<commit message>`

**Files Changed:**
- `path/to/file1.kt` — [description]
- `path/to/file2.swift` — [description]

**Verification:**
- Build: ✅ Passing
- Tests: ✅ X tests passing
- Lint: ✅ No errors
```

**Verification Checklist:**

After committing, agents MUST:

1. **Retrieve Commit Hash**
   ```bash
   git rev-parse --short HEAD
   ```

2. **Confirm Commit Exists**
   ```bash
   git log -1 --oneline
   ```

3. **Report to User**
   - Provide the short-hash of the commit
   - Summarize what was accomplished
   - List key files that were modified
   - Confirm build and test status

---

### Operational Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      TASK EXECUTION FLOW                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   RECEIVE    │───►│   EXECUTE    │───►│   VALIDATE   │      │
│  │    TASK      │    │    TASK      │    │   CRITERIA   │      │
│  └──────────────┘    └──────────────┘    └──────┬───────┘      │
│                                                 │              │
│                                     ┌───────────┴───────────┐  │
│                                     │                       │  │
│                               ┌─────▼─────┐          ┌──────▼──┐│
│                               │  CRITERIA │          │ CRITERIA ││
│                               │   MET ✅   │          │ NOT MET ❌││
│                               └─────┬─────┘          └──────┬──┘│
│                                     │                       │  │
│                                     ▼                       ▼  │
│                          ┌──────────────────┐    ┌─────────────┐│
│                          │  AUTO-COMMIT     │    │ FIX ISSUES  ││
│                          │  (git add/commit)│    │ (loop back) ││
│                          └────────┬─────────┘    └─────────────┘│
│                                   │                             │
│                                   ▼                             │
│                          ┌──────────────────┐                   │
│                          │  VERIFICATION    │                   │
│                          │  SUMMARY         │                   │
│                          │  (report to user)│                   │
│                          └──────────────────┘                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

### Exceptions

The following scenarios **exempt** agents from automatic commit behavior:

| Scenario                                 | Required Action                                  |
| ---------------------------------------- | ------------------------------------------------ |
| User explicitly requests review          | Wait for approval before committing              |
| Task involves security-sensitive changes | Request human review before committing           |
| Ambiguous requirements                   | Seek clarification before proceeding             |
| Exploratory/research tasks               | Present findings; do not commit unless requested |
| Breaking changes to shared contract      | Document in plan, flag for review, then commit   |

---

### Enforcement

- ✅ Agents MUST follow this protocol for all completed tasks
- ✅ Plan documents MUST reflect the commit hash in the Outcome section
- ✅ Failure to commit after meeting criteria is a protocol violation
- ⚠️ If external factors prevent committing (e.g., git errors), report to user immediately

---

## Change Log

| Version | Date       | Changes                                                                                       |
| ------- | ---------- | --------------------------------------------------------------------------------------------- |
| 1.4.0   | 2026-02-04 | Added Operational Protocols section for autonomous task finalization and automated commits    |
| 1.3.0   | 2026-02-04 | Added Mandatory Synchronization Rule for keeping AGENTS.md aligned with architectural changes |
| 1.2.0   | 2026-02-04 | Added Firebase Specifics section for `pushed_firebase` middleware component                   |
| 1.1.0   | 2026-02-04 | Added Traceability & Execution Logging governance rule                                        |
| 1.0.0   | 2026-02-04 | Initial AGENTS.md creation                                                                    |

---

*This document is maintained by the Pushed development team. For questions or updates, open an issue in this repository.*
