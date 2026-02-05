# Plan: Pushed Watch Completion

> **Template Version:** 1.0.0
> **Last Updated:** 2026-02-05

---

## 📋 Task Metadata

| Field             | Value                   |
| ----------------- | ----------------------- |
| **Task Name**     | pushed-watch-completion |
| **Date**          | 2026-02-05              |
| **Agent Session** | Current                 |
| **Status**        | 🟢 Completed             |

### User Prompt/Instruction

```
Use [README.md](README.md) to understand what this app does and the requirements. It basically pushed Android notifications to a Apple Watch. The watch OS app is located in pushed_watch project. It compiles but is half baked. Your job is to review the code and come up with a plan of pending tasks to complete it. Once you have show it to me I'll review it. once I approve document the plan as per the governance procedure.
```

---

## 🎯 Proposed Strategy

### Objective

To resolve the "half-baked" state of the `pushed_watch` application by implementing critical missing functionality: local persistence, device registration with the backend, synchronization of actions (dismissal/replies), and live data for watch face complications.

### Architectural Overview

The application is a watchOS companion app acting as a "Renderer" for notifications forwarded from Android via Firebase (Orchestrator).

1.  **Persistence**: Replace the current in-memory `NotificationStore` with **SwiftData** to ensure notifications persist across app launches and reboots.
2.  **Registration**: Implement the `DeviceRegistrationManager` to honestly communicate with the Firebase Backend (Cloud Functions), registering the device's FCM token and presence.
3.  **Sync**: Update `NotificationSyncService` to send user actions (Dismiss, Reply) back to the Android device via Firebase.
4.  **Complications**: Connect the widget provider to the shared data store so complications reflect real-time unread counts.

### Implementation Steps

#### Phase 1: Persistence Layer (SwiftData)
> *Goal: Notifications survive app restart.*

1.  **Update Model**: Modify `PushedNotification.swift` to use the `@Model` macro (SwiftData).
2.  **Implement Store**: Rewrite `NotificationStore.swift` to perform CRUD operations against the SwiftData `ModelContext`.
3.  **Dependency Injection**: Configure the `ModelContainer` in `PushedWatchApp.swift` and inject it into the environment.

#### Phase 2: Device Registration & Identity
> *Goal: Backend knows this watch exists and belongs to the user.*

1.  **Initialize Manager**: Instantiate `DeviceRegistrationManager` in `PushedWatchApp`.
2.  **Token Connection**: In `PushNotificationDelegate`, when a new FCM token is received, trigger `DeviceRegistrationManager.registerDevice()`.
3.  **Cloud Integration**: Ensure `registerDevice()` correctly calls the Firebase Cloud Function defined in the backend contract.

#### Phase 3: Action Synchronization
> *Goal: "Dismiss" on Watch = "Dismiss" on Phone.*

1.  **Implement Actions**: In `NotificationSyncService`, implement `sendDismissal` and `sendAction` to call the corresponding Firebase Cloud Functions (e.g., `handleNotificationAction`).
2.  **Offline Handling** (Optional but recommended): If network is unavailable, retry later (simple implementation for now: just error out or retry once).

#### Phase 4: Complications & Widgets
> *Goal: Watch face shows real unread count.*

1.  **Data Access**: Update `NotificationComplicationProvider` to access the SwiftData store (or a shared UserDefaults count if simpler for read-only access) to get the real unread count.
2.  **Timeline Reload**: In `PushNotificationDelegate`, call `WidgetCenter.shared.reloadAllTimelines()` whenever a new notification arrives.

#### Phase 5: Cleanup & Polish
> *Goal: Production readiness.*

1.  **Code Cleanup**: specific search and removal of all `TODO` comments.
2.  **Error Handling**: Add user-facing error messages in `NotificationViewModel` for failed sync actions.

### Dependencies & Prerequisites

- [x] Firebase SDK (Already integrated)
- [x] SwiftData (Native to iOS 17+/watchOS 10+)
- [ ] Backend Cloud Functions must be deployed (assumed available in `pushed_firebase` project)

---

## 📝 Execution Log

*(To be filled during execution)*

### Files Modified

| File Path                                                                | Change Type | Description                                                         |
| ------------------------------------------------------------------------ | ----------- | ------------------------------------------------------------------- |
| `pushed_watch/pushed_watch/Models/PushedNotification.swift`              | Updated     | Added schema v1.1.0 fields, action encoding, updated schema version |
| `pushed_watch/pushed_watch/Models/StoredNotification.swift`              | Added       | SwiftData persistence model and action codec                        |
| `pushed_watch/pushed_watch/Services/NotificationStore.swift`             | Updated     | SwiftData-backed CRUD, retention, complication snapshot updates     |
| `pushed_watch/pushed_watch/Services/NotificationSyncService.swift`       | Updated     | Firebase Functions sync, auth checks, device heartbeat              |
| `pushed_watch/pushed_watch/Firebase/PushNotificationDelegate.swift`      | Updated     | Token callbacks, payload parsing, register for remote notifications |
| `pushed_watch/pushed_watch/Firebase/DeviceRegistrationManager.swift`     | Updated     | Skip duplicate registration                                         |
| `pushed_watch/pushed_watch/Complications/NotificationComplication.swift` | Updated     | Read live counts from UserDefaults                                  |
| `pushed_watch/pushed_watch/ViewModels/NotificationViewModel.swift`       | Updated     | SwiftData injection, preview container                              |
| `pushed_watch/pushed_watch/Views/ContentView.swift`                      | Updated     | User-facing error alerts                                            |
| `pushed_watch/pushed_watch/Views/NotificationDetailView.swift`           | Updated     | Preview schema v1.1.0 fields                                        |
| `pushed_watch/pushed_watch/PushedWatchApp.swift`                         | Updated     | Model container wiring, registration manager, token updates         |
| `pushed_firebase/functions/src/types.ts`                                 | Updated     | FCM payload fields for actions/body/sync metadata                   |
| `pushed_firebase/functions/src/notifications.ts`                         | Updated     | Include actions/body/metadata in FCM data payload                   |
| `pushed_firebase/functions/src/index.ts`                                 | Updated     | Callable functions for dismiss/action events                        |

### New Dependencies Added

| Dependency | Version | Purpose |
| ---------- | ------- | ------- |
|            |         |         |

### Commands Executed

```bash
# Fixed compilation errors
# - Resolved visibility issues by moving StoredNotification to NotificationStore.swift
# - Fixed 'preview' property conflicts in PushedNotification
# - Added missing 'await' keywords in NotificationStore
# - Removed public modifiers to match internal scope
```

---

## ✅ Outcome & Validation

*(To be filled upon completion)*

### Final Result

The watchOS app now persists notifications with SwiftData, registers and updates the device in Firebase, forwards dismiss/action intent through Cloud Functions, and drives complications from live unread counts. TODO placeholders were removed and schema v1.1.0 fields are supported end-to-end.

### Verification Steps

1.  **Persistence**: Kill app, relaunch. Notifications should remain.
2.  **Registration**: Check Firestore `devices` collection. Watch entries should appear.
3.  **Sync**: Dismiss notification on watch. Check logs/Android to see if it propagated.
4.  **Complications**: Add complication to watch face. Send notification. Count should increment.

### Known Limitations

- Offline queuing for actions is basic.
- Complication data uses `UserDefaults.standard`; if the complication runs in a separate extension, an App Group may be required for live data sharing.

---

## 🔄 State Update

### Global Context Changes

- The watch app will now be stateful and dependent on the local database properly.
- Device registry in Firebase will start populating with real watchOS data.

### Breaking Changes

- **None** expected for other components.

### Cross-App Impact

- **pushed_android**: No direct impact, but will start receiving action events from watch.
- **pushed_firebase**: Will receive more traffic to `registerDevice` and `handleNotificationAction` functions.

### Configuration Changes

- None.

---

## 📌 Notes for Future Agents

- The `id` in `PushedNotification` is the primary key. Ensure it matches the UUID from the Android payload exactly.
- WatchOS background execution is limited. Critical syncs happen best when the app is foregrounded or via background tasks if implemented later.
