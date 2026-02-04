# AGENTS.md — Firebase (`pushed_firebase`)

> **Role:** Orchestrator  
> **Description:** Middleware for auth, data sync, and push notification dispatch  
> Reference: [pushed_firebase/README.md](./README.md)

---

## Role & Responsibilities

`pushed_firebase` is the **middleware orchestrator** that bridges Android and watchOS platforms:

| Function            | Description                                                   |
| ------------------- | ------------------------------------------------------------- |
| **Authentication**  | Shared Firebase Auth identity across platforms (Google/Email) |
| **Data Storage**    | Firestore database for device registry and notification queue |
| **Push Dispatch**   | Cloud Functions trigger FCM notifications to watchOS          |
| **Device Registry** | Tracks registered Android sender and watchOS receiver devices |

---

## Technology Stack

| Layer          | Technology                     |
| -------------- | ------------------------------ |
| Runtime        | Node.js 20+                    |
| Language       | TypeScript (strict mode)       |
| Functions      | Cloud Functions v2 (2nd gen)   |
| Database       | Cloud Firestore                |
| Authentication | Firebase Auth                  |
| Messaging      | Firebase Cloud Messaging (FCM) |

---

## Project Structure

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

---

## Cloud Functions

### Firestore Triggers

| Function                | Trigger                                                | Description                                      |
| ----------------------- | ------------------------------------------------------ | ------------------------------------------------ |
| `onNotificationCreated` | `users/{userId}/notifications/{notificationId}` create | Dispatches FCM to all registered watchOS devices |
| `onNotificationDeleted` | `users/{userId}/notifications/{notificationId}` delete | Cleanup handler (optional)                       |

### Callable Functions

| Function               | Purpose                                        |
| ---------------------- | ---------------------------------------------- |
| `registerDevice`       | Register Android/watchOS device with FCM token |
| `unregisterDevice`     | Remove device from registry                    |
| `updateDeviceToken`    | Refresh FCM token after rotation               |
| `deviceHeartbeat`      | Update device lastSeen timestamp               |
| `getRegisteredDevices` | List all devices for current user              |

---

## Firestore Schema

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

---

## Security Rules

**Security Constraints:**
1. All operations require authentication (`request.auth != null`).
2. Users can only access their own data (`request.auth.uid == userId`).
3. Device FCM tokens are protected.
4. Notification inputs must be validated.

---

## Cloud Function Guidelines

**Best Practices:**
- ALWAYS: Use v2 Cloud Functions syntax (`firebase-functions/v2`).
- ALWAYS: Specify region (`us-central1` recommended) and resource limits.
- ALWAYS: Validate authentication in callable functions.

---

## Error Handling

**Error Handling Standards:**
- Log errors with context (`userId`, `notificationId`).
- Update documents with error status (e.g., `dispatchError`).
- Clean up invalid FCM tokens automatically.

---

## Build Commands

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

---

## Environment & Configuration

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
