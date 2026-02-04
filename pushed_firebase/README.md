# Pushed Firebase - Notification Forwarding Middleware

This Firebase project serves as the middleware layer for the Pushed cross-platform notification forwarding system. It orchestrates notification delivery from Android sender devices to watchOS receiver clients.

## Architecture

```
┌─────────────────────┐     ┌────────────────────────────────────┐     ┌─────────────────────┐
│   Android Device    │     │         pushed_firebase            │     │   watchOS Client    │
│   ─────────────────  │     │         ────────────────           │     │   ─────────────────  │
│   • Auth + Write    ├────►│   Firestore → Functions → FCM     │────►│   • FCM + Display   │
└─────────────────────┘     └────────────────────────────────────┘     └─────────────────────┘
```

## Features

- **Firebase Authentication**: Shared user identity across platforms (Google/Email)
- **Firestore Database**: Device registry and notification queuing
- **Cloud Functions**: Background trigger on notification writes
- **FCM Dispatch**: Push notifications to registered watchOS devices
- **Multi-Device Support**: Multiple Android senders, single watchOS receiver

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

## Setup

### Prerequisites

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com)

### Installation

1. Navigate to the functions directory:
   ```bash
   cd pushed_firebase/functions
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Build the functions:
   ```bash
   npm run build
   ```

### Configuration

1. Update `.firebaserc` with your project ID:
   ```json
   {
     "projects": {
       "default": "your-firebase-project-id"
     }
   }
   ```

2. Enable required Firebase services in the console:
   - Authentication (Google & Email/Password)
   - Firestore Database
   - Cloud Functions
   - Cloud Messaging

3. For APNs (required for watchOS):
   - Generate APNs Authentication Key in Apple Developer Console
   - Upload the key to Firebase Console → Project Settings → Cloud Messaging

### Deployment

Deploy all Firebase resources:
```bash
firebase deploy
```

Or deploy specific resources:
```bash
# Deploy only functions
firebase deploy --only functions

# Deploy only firestore rules
firebase deploy --only firestore:rules
```

### Local Development

Start the Firebase emulators:
```bash
firebase emulators:start
```

Access the Emulator UI at http://localhost:4000

## Firestore Schema

### Users Collection

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
        └── createdAt: timestamp
```

## Cloud Functions

### Triggers

| Function                | Trigger          | Description                       |
| ----------------------- | ---------------- | --------------------------------- |
| `onNotificationCreated` | Firestore Create | Dispatches FCM to watchOS devices |
| `onNotificationDeleted` | Firestore Delete | Cleanup handler (optional)        |

### Callable Functions

| Function               | Description                              |
| ---------------------- | ---------------------------------------- |
| `registerDevice`       | Register a device for push notifications |
| `unregisterDevice`     | Remove a device from registry            |
| `updateDeviceToken`    | Update FCM token after refresh           |
| `deviceHeartbeat`      | Update device lastSeen timestamp         |
| `getRegisteredDevices` | List all registered devices              |

## Security

- All Firestore operations require authentication
- Users can only access their own data (user-isolated)
- Device FCM tokens are protected
- Notification validation enforced in security rules
- Invalid tokens are automatically cleaned up

## Environment Variables

For local development with emulators, create a `.env` file:
```
FIREBASE_CONFIG={"projectId":"pushed-firebase",...}
GCLOUD_PROJECT=pushed-firebase
```

## Monitoring

View function logs:
```bash
firebase functions:log
```

Or in the Firebase Console → Functions → Logs

## Troubleshooting

### Common Issues

1. **FCM not reaching watchOS**:
   - Verify APNs key is uploaded to Firebase
   - Check device token is valid and current
   - Ensure proper bundle identifier configuration

2. **Function not triggering**:
   - Verify Firestore path matches trigger pattern
   - Check function deployment status
   - Review logs for errors

3. **Authentication errors**:
   - Ensure user is signed in on both platforms
   - Verify Firebase project configuration
   - Check google-services.json / GoogleService-Info.plist

## Related Documentation

- [AGENTS.md](/AGENTS.md) - Project governance
- [Contract Schema](/contract/notification_schema.json) - Notification payload format
- [Implementation Plan](/plans/2026-02-04-firebase-orchestrator-implementation.md)

---

*Part of the Pushed Notification Bridge System*
