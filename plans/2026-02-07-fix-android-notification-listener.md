# Plan: Fix Android Notification Listener

> **Template Version:** 1.0.0
> **Last Updated:** 2026-02-07

---

## 📋 Task Metadata

| Field             | Value                             |
| ----------------- | --------------------------------- |
| **Task Name**     | Fix Android Notification Listener |
| **Date**          | 2026-02-07                        |
| **Agent Session** | Current                           |
| **Status**        | 🟢 Completed                       |

### User Prompt/Instruction

```
why is the android notification listener in pushed_android not working.
```

---

## 🎯 Proposed Strategy

### Objective

Investigate why the Android Notification Listener Service appeared to be non-functional and ensure it correctly intercepts and processes notifications.

### Architectural Overview

The `PushedNotificationListener` extends `NotificationListenerService` and uses a `NotificationFilter` to determine which notifications to forward. The issue was suspected to be either a logic error in filtering, a permission issue, or a lack of visibility into why notifications were being ignored.

### Implementation Steps

1.  **Audit Code**: Review `PushedNotificationListener` and `NotificationFilter` for logic errors.
2.  **Add Observability**: Add detailed logging to `NotificationFilter` to explicitly state *why* a notification is skipped (e.g., blocked package, low priority, self-notification).
3.  **Fix Bugs**: Found and fixed a bug where `SYSTEM_BLOCKLIST` was defined but never checked.
4.  **Verify**: Use `adb` to post test notifications and verify logs.

### Dependencies & Prerequisites

- Android `NotificationListenerService` permission must be granted by the user.
- `adb` access for testing.

---

## 📝 Execution Log

### Files Modified

| File Path                                                                                   | Change Type | Description                                                                        |
| ------------------------------------------------------------------------------------------- | ----------- | ---------------------------------------------------------------------------------- |
| `pushed_android/app/src/main/java/com/pushed/android/service/NotificationFilter.kt`         | Modified    | Added detailed logging for all filter steps; Fixed `SYSTEM_BLOCKLIST` ignored bug. |
| `pushed_android/app/src/main/java/com/pushed/android/service/PushedNotificationListener.kt` | Modified    | Added logging for self-notification skipping.                                      |

### Commands Executed

```bash
adb shell settings get secure enabled_notification_listeners
adb logcat -d -t 500
adb shell cmd notification post -S bigtext -t 'Test Notification' 'tag' 'Test Body'
```

---

## ✅ Outcome & Validation

### Final Result

The listener was found to be functional, but quiet failures (due to valid filtering or permissions) made it appear broken. 

1.  **Bug Fix**: `SYSTEM_BLOCKLIST` is now correctly enforced.
2.  **Observability**: Logcat now clearly shows "Skipping [reason]" for every filtered notification.
3.  **Verification**: Verified that `adb` posted notifications are received and processed.
4.  **User Education**: Clarified that Emulator SMS does not always post system notifications, leading to false negatives in testing.

### Verification Steps

1.  **Run App**: Ensure Notification Access permission is granted.
2.  **Trigger Notification**: Run `adb shell cmd notification post -t 'Test' 'id' 'Body'`.
3.  **Check Logs**: `adb logcat -s PushedNotificationListener NotificationFilter` should show "Got a new notification" and "Processed notification".

### Test Results

| Test Type      | Status | Notes                      |
| -------------- | ------ | -------------------------- |
| Manual Testing | ✅      | Verified with ADB command. |

---

## 🔄 State Update

### Global Context Changes
No global state changes.

### Breaking Changes
None.

### Cross-App Impact
- **pushed_android**: Better debugging logs.
- **pushed_watch**: No impact.

### Configuration Changes
None.

### Documentation Updates Required
None.

---

## 📌 Notes for Future Agents

- When debugging notification listeners, always check `adb shell settings get secure enabled_notification_listeners` first.
- Emulator SMS tools are unreliable for testing notification listeners; use `adb shell cmd notification post` instead.

---

*This plan follows the Traceability & Execution Logging protocol defined in [AGENTS.md](../AGENTS.md)*
