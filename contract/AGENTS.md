# AGENTS.md — Shared Contract

> This document defines the shared notification payload contract between all platforms.

---

## Notification Payload Schema (v1.0.0)

See `shared/contract` for the authoritative schema.  
Key fields: `id` (UUID), `schemaVersion`, `timestamp`, `title`, `packageName`, `category`, `actions`.

---

## Platform-Specific Implementations

### Android (Kotlin)

Data class `PushedNotification` must be `@Serializable` and match the schema.  
See `PushedNotification.kt`.

### watchOS (Swift)

Struct `PushedNotification` must conform to `Codable`, `Identifiable`, `Hashable`.  
See `PushedNotification.swift`.

---

## Schema Evolution Rules

- Both apps MUST validate incoming payloads against expected schema versions
- Maintain backward compatibility for at least 2 minor versions
- Breaking changes require coordination across all platforms

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
