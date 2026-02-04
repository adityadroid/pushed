# Pushed — Cross-Platform Notification Bridge

A notification bridging system that forwards Android notifications to an Apple Watch.

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        PUSHED MONOREPO                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────┐         ┌─────────────────────┐       │
│  │   pushed_android    │         │    pushed_watch     │       │
│  │   ───────────────   │         │   ───────────────   │       │
│  │   LISTENER          │         │   RENDERER          │       │
│  │                     │         │                     │       │
│  │   • Intercepts      │  JSON   │   • Receives        │       │
│  │   • Filters         │◄───────►│   • Displays        │       │
│  │   • Transforms      │ Schema  │   • Manages         │       │
│  │   • Forwards        │         │   • Archives        │       │
│  │                     │         │                     │       │
│  │   Kotlin + Compose  │         │   Swift + SwiftUI   │       │
│  └─────────────────────┘         └─────────────────────┘       │
│              │                              │                   │
│              └──────────────┬───────────────┘                   │
│                             │                                   │
│                   ┌─────────▼─────────┐                        │
│                   │     contract/     │                        │
│                   │   ─────────────   │                        │
│                   │   JSON Schema     │                        │
│                   │   v1.0.0          │                        │
│                   └───────────────────┘                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
pushed/
├── AGENTS.md                    # AI agent governance & coding standards
├── README.md                    # This file
├── contract/                    # Shared data contract
│   ├── README.md               
│   └── notification_schema.json # JSON Schema definition
├── pushed_android/              # Android app (Listener)
│   ├── README.md               
│   └── app/                    
│       └── src/main/           
│           ├── AndroidManifest.xml
│           └── java/com/pushed/android/
│               ├── PushedApplication.kt
│               ├── di/AppModule.kt
│               ├── service/
│               │   ├── PushedNotificationListener.kt
│               │   └── NotificationFilter.kt
│               ├── data/
│               │   ├── model/
│               │   ├── local/
│               │   ├── repository/
│               │   └── preferences/
│               └── sync/WatchSyncManager.kt
├── pushed_watch/                # watchOS app (Renderer)
│   ├── README.md               
│   └── pushed_watch/           
│       ├── PushedWatchApp.swift
│       ├── Models/
│       ├── Views/
│       ├── ViewModels/
│       ├── Services/
│       └── Complications/
├── sample_android.md            # Android guidelines reference
└── sample_ios.md                # iOS/watchOS guidelines reference
```

## 🚀 Getting Started

### Prerequisites

**Android Development:**
- Android Studio Hedgehog or later
- JDK 17+
- Android SDK API 34

**watchOS Development:**
- Xcode 16.0 or later
- macOS Sonoma or later
- watchOS 11.0 SDK

### Building

**Android:**
```bash
cd pushed_android
./gradlew assembleDemoDebug
```

**watchOS:**
```bash
cd pushed_watch
open pushed_watch.xcodeproj
# Build via Xcode (Cmd+B)
```

## 📋 Shared Contract

Both apps communicate using a JSON-based notification schema:

```json
{
  "id": "uuid-v4",
  "schemaVersion": "1.0.0",
  "timestamp": "2026-02-04T09:00:00Z",
  "title": "Notification Title",
  "body": "Notification content...",
  "packageName": "com.example.app",
  "appName": "Example App",
  "category": "message",
  "priority": "high",
  "actions": [
    { "id": "reply", "label": "Reply" }
  ]
}
```

See [`contract/notification_schema.json`](contract/notification_schema.json) for the full schema.

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [AGENTS.md](AGENTS.md) | AI agent governance, coding standards, sync protocols |
| [contract/README.md](contract/README.md) | Shared schema documentation |
| [pushed_android/README.md](pushed_android/README.md) | Android app documentation |
| [pushed_watch/README.md](pushed_watch/README.md) | watchOS app documentation |

## 🧪 Testing

**Android:**
```bash
./gradlew :pushed_android:testDemoDebugUnitTest
```

**watchOS:**
```bash
xcodebuild test -scheme pushed_watch \
    -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)'
```

## 📄 License

[Add your license here]

## 🤝 Contributing

See [AGENTS.md](AGENTS.md) for coding standards and commit message formats.
