# Plan: Cross-Platform Notification Forwarding via Firebase Orchestrator

> **Template Version:** 1.0.0  
> **Last Updated:** 2026-02-04

---

## 📋 Task Metadata

| Field             | Value                                                            |
| ----------------- | ---------------------------------------------------------------- |
| **Task Name**     | Cross-Platform Notification Forwarding via Firebase Orchestrator |
| **Date**          | 2026-02-04                                                       |
| **Agent Session** | Current Session                                                  |
| **Status**        | 🔵 In Progress                                                    |

### User Prompt/Instruction

```
Subject: Implementation of Cross-Platform Notification Forwarding via Firebase Orchestrator

Project Scope: Architect and deploy a new Firebase project, pushed_firebase, to act as a 
middleware layer. The goal is to forward system notifications from multiple Android "sender" 
devices to a WatchOS "receiver" client for the same authenticated user.

Key Requirements:
1. Architecture & Middle Layer (pushed_firebase): Firebase Auth, Cloud Functions, Firestore
2. Android Client: NotificationListenerService, Multi-Client Support, Firestore Upload
3. WatchOS Client: FCM Listener, Firebase Auth, Signing Identity (adityagurjar.it18@gmail.com)
4. Synchronization: Handle multiple Android devices forwarding to single watchOS client
```

---

## 🎯 Proposed Strategy

### Objective

Implement a complete Firebase-based notification forwarding system that:
1. Uses Firebase as middleware layer between Android senders and watchOS receivers
2. Authenticates users across platforms via Firebase Auth (shared UID)
3. Triggers Cloud Functions on Firestore writes to dispatch FCM payloads
4. Supports multiple Android devices per user with collision-free notification forwarding

### Architecture Overview

```
┌─────────────────────┐     ┌──────────────────────────────────────────────────────────────────┐     ┌─────────────────────┐
│   Android Device A  │     │                    pushed_firebase (Cloud)                       │     │   watchOS Client    │
│   ─────────────────  │     │                    ─────────────────────────                    │     │   ─────────────────  │
│   • NotificationList │     │  ┌─────────────┐  ┌─────────────────────┐  ┌─────────────────┐  │     │   • FCM Listener    │
│   • Firebase Auth   ├────►│  │  Firebase   │  │      Firestore      │  │  Cloud Function │  │────►│   • Firebase Auth   │
│   • Firestore Write │     │  │    Auth     │  │ users/{uid}/        │  │ onDocumentCreated│  │     │   • Display Notif   │
└─────────────────────┘     │  │  (Google/   │  │   notifications/    │  │ Trigger → FCM   │  │     └─────────────────────┘
                            │  │   Email)    │  │   devices/          │  │ Dispatch        │  │                            
┌─────────────────────┐     │  └─────────────┘  └─────────────────────┘  └─────────────────┘  │                            
│   Android Device B  │     │                                                                  │                            
│   ─────────────────  │     │                    Firebase Cloud Messaging                     │                            
│   • NotificationList │     │                    ─────────────────────────                    │                            
│   • Firebase Auth   ├────►│                    • APNs for watchOS delivery                  │                            
│   • Firestore Write │     │                    • Per-user token registry                    │                            
└─────────────────────┘     └──────────────────────────────────────────────────────────────────┘                            
```

### Firestore Data Schema

```
users/
└── {userId}/
    ├── profile/
    │   ├── email: string
    │   ├── createdAt: timestamp
    │   └── updatedAt: timestamp
    │
    ├── devices/
    │   └── {deviceId}/
    │       ├── type: "android" | "watchos"
    │       ├── fcmToken: string
    │       ├── deviceName: string
    │       ├── lastSeen: timestamp
    │       └── createdAt: timestamp
    │
    └── notifications/
        └── {notificationId}/
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
            └── ... (other notification fields)
```

### Implementation Steps

1. **Step 1**: Create Firebase project structure and configuration
2. **Step 2**: Implement Cloud Functions (TypeScript) with Firestore trigger
3. **Step 3**: Add Firebase SDK dependencies to Android app
4. **Step 4**: Implement Android Firebase Auth and Firestore integration
5. **Step 5**: Update WatchSyncManager to write notifications to Firestore
6. **Step 6**: Add Firebase SDK to watchOS app
7. **Step 7**: Implement watchOS FCM listener and Firebase Auth
8. **Step 8**: Test multi-device synchronization

### Dependencies & Prerequisites

- [ ] Firebase CLI installed
- [ ] Node.js and npm for Cloud Functions
- [ ] Firebase project created in console
- [ ] Apple Developer account access (adityagurjar.it18@gmail.com)
- [ ] APNs certificate for FCM
- [ ] Android google-services.json
- [ ] iOS GoogleService-Info.plist

---

## 📝 Execution Log

### Files to Create/Modify

| File Path                                        | Change Type | Description                    |
| ------------------------------------------------ | ----------- | ------------------------------ |
| `pushed_firebase/`                               | Created     | New Firebase project directory |
| `pushed_firebase/firebase.json`                  | Created     | Firebase configuration         |
| `pushed_firebase/firestore.rules`                | Created     | Firestore security rules       |
| `pushed_firebase/firestore.indexes.json`         | Created     | Firestore indexes              |
| `pushed_firebase/functions/`                     | Created     | Cloud Functions directory      |
| `pushed_firebase/functions/src/index.ts`         | Created     | Main Cloud Functions entry     |
| `pushed_firebase/functions/src/notifications.ts` | Created     | Notification forwarding logic  |
| `pushed_firebase/functions/src/types.ts`         | Created     | TypeScript type definitions    |
| `pushed_android/app/build.gradle.kts`            | Modified    | Add Firebase dependencies      |
| `pushed_android/app/src/.../auth/`               | Created     | Firebase Auth implementation   |
| `pushed_android/app/src/.../firebase/`           | Created     | Firestore integration          |
| `pushed_watch/.../Firebase/`                     | Created     | Firebase SDK integration       |
| `pushed_watch/.../Auth/`                         | Created     | Firebase Auth for watchOS      |

### New Dependencies Added

| Dependency         | Version | Platform  | Purpose                 |
| ------------------ | ------- | --------- | ----------------------- |
| firebase-admin     | ^12.0.0 | Functions | Firebase Admin SDK      |
| firebase-functions | ^6.0.0  | Functions | Cloud Functions SDK     |
| firebase-auth      | BOM     | Android   | Firebase Authentication |
| firebase-firestore | BOM     | Android   | Cloud Firestore         |
| firebase-messaging | BOM     | Android   | FCM for Android         |
| FirebaseAuth       | 11.0.0  | watchOS   | Firebase Auth for iOS   |
| FirebaseFirestore  | 11.0.0  | watchOS   | Firestore for iOS       |
| FirebaseMessaging  | 11.0.0  | watchOS   | FCM for watchOS         |

---

## 🔄 State Update

### Breaking Changes

> ⚠️ **Breaking Change Alert**: This introduces Firebase as a required middleware layer

| Component Affected | Change                       | Migration Path    |
| ------------------ | ---------------------------- | ----------------- |
| `pushed_android`   | Requires Firebase Auth login | Add login UI flow |
| `pushed_watch`     | Requires Firebase Auth login | Add login UI flow |
| `contract`         | Add sourceDeviceId field     | Schema v1.1.0     |

### Cross-App Impact

- **pushed_android**: Must authenticate user and write to Firestore
- **pushed_watch**: Must authenticate and listen for FCM push notifications
- **pushed_firebase**: New component - acts as middleware orchestrator

### WatchOS Signing Identity

> ⚠️ **MANDATORY**: Use signing identity `adityagurjar.it18@gmail.com` for all certificates, identifiers, and provisioning profiles.
> 
> **STRICT PROSCRIPTION**: Do NOT use `a.gurjar@scbank.com.eg` for this project.

---

## 📚 References

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Firestore Triggers](https://firebase.google.com/docs/functions/firestore-events)
- [FCM for iOS/watchOS](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [Firebase Auth on Android](https://firebase.google.com/docs/auth/android/start)

---

*This plan follows the Traceability & Execution Logging protocol defined in [AGENTS.md](../AGENTS.md)*
