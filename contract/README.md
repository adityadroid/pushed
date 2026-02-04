# Pushed Contract

This directory contains the **shared contract** between the Android listener (`pushed_android`) and the watchOS renderer (`pushed_watch`).

## Structure

```
contract/
├── README.md                    # This file
├── notification_schema.json     # JSON Schema for notification payload
└── versions/                    # Historical schema versions
    └── v1.0.0.json             # Version 1.0.0 schema
```

## Schema Overview

The `PushedNotification` schema defines the structure for notification data transferred between platforms:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | ✅ | Unique notification identifier |
| `schemaVersion` | String | ✅ | Schema version (semver) |
| `timestamp` | ISO 8601 | ✅ | When notification was received |
| `title` | String | ✅ | Notification title |
| `body` | String | ❌ | Notification body text |
| `packageName` | String | ✅ | Source app package name |
| `appName` | String | ❌ | Human-readable app name |
| `category` | Enum | ❌ | Notification category |
| `priority` | Enum | ❌ | Priority level |
| `actions` | Array | ❌ | Available actions |
| `groupKey` | String | ❌ | Grouping key |
| `isOngoing` | Boolean | ❌ | Persistent notification flag |
| `iconData` | Base64 | ❌ | App icon (max 10KB) |

## Categories

```
message  - Chat/messaging apps
email    - Email notifications
social   - Social media
news     - News and updates
promo    - Promotional content
reminder - Reminders and todos
call     - Voice/video calls
transport - Maps/navigation
alarm    - Alarms and timers
other    - Uncategorized
```

## Priorities

```
min     - Silent, no interruption
low     - Low urgency
default - Normal priority
high    - Important, may interrupt
max     - Critical, always interrupt
```

## Versioning Policy

1. **Backward Compatibility**: New minor versions MUST be backward compatible
2. **Deprecation**: Fields can only be removed in major versions
3. **Required Fields**: Cannot add new required fields in minor versions
4. **Validation**: Both apps MUST validate against expected schema version

## Usage

### Android (Kotlin with kotlinx.serialization)

```kotlin
import kotlinx.serialization.json.Json
import com.pushed.contract.PushedNotification

val json = Json { ignoreUnknownKeys = true }
val notification = json.decodeFromString<PushedNotification>(jsonString)
```

### watchOS (Swift with Codable)

```swift
import Foundation

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
let notification = try decoder.decode(PushedNotification.self, from: jsonData)
```

## Validation

Use a JSON Schema validator to validate payloads:

```bash
# Using ajv-cli
npx ajv validate -s notification_schema.json -d sample_notification.json
```

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-02-04 | Initial schema release |
