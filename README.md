# Pushed — Cross-Platform Notification Bridge

A notification bridging system that forwards Android notifications to an Apple Watch via Firebase Cloud Messaging.

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        PUSHED MONOREPO                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────┐     ┌─────────────────────────┐     ┌─────────────────────┐
│  │   pushed_android    │     │     pushed_firebase     │     │    pushed_watch     │
│  │   ───────────────   │     │    ───────────────      │     │   ───────────────   │
│  │   • Intercept       │     │   • Authenticate        │     │   • Receive         │
│  │   • Filter          │────►│   • Queue & Store       │────►│   • Display         │
│  │   • Transform       │     │   • Dispatch via FCM    │     │   • Manage          │
│  │   • Write to DB     │     │   • Device Registry     │     │   • Archive         │
│  └─────────────────────┘     └─────────────────────────┘     └─────────────────────┘
│         LISTENER                   ORCHESTRATOR                    RENDERER
│                                                                 │
│                            Shared Contract (JSON Schema)        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
pushed/
├── AGENTS.md                    # AI agent governance & coding standards
├── README.md                    # This file
├── contract/                    # Shared data contract & JSON Schema
│   ├── README.md               
│   └── notification_schema.json 
├── pushed_android/              # Android app (Listener)
│   ├── README.md               
│   └── app/src/main/java/com/pushed/android/
├── pushed_firebase/             # Firebase Backend (Orchestrator)
│   ├── README.md
│   ├── functions/               # Cloud Functions (TypeScript)
│   ├── firestore.rules          # Database security rules
│   └── firebase.json            # Deployment config
├── pushed_watch/                # watchOS app (Renderer)
│   ├── README.md               
│   └── pushed_watch/            # Swift/SwiftUI sources
├── sample_android.md            # Android guidelines reference
└── sample_ios.md                # iOS/watchOS guidelines reference
```

## 🚀 Getting Started

### Prerequisites

**Android Development:**
- Android Studio Hedgehog or later
- JDK 17+
- Android SDK API 34

**Firebase Development:**
- Node.js 20+
- Firebase CLI (`npm install -g firebase-tools`)
- Functional Firebase project with Auth, Firestore, and Functions enabled

**watchOS Development:**
- Xcode 16.0 or later
- macOS Sonoma or later
- watchOS 11.0 SDK

### Building

**1. Android App:**
```bash
cd pushed_android
./gradlew assembleDemoDebug
```

**2. Firebase Backend:**
```bash
cd pushed_firebase/functions
npm install
npm run build
# Deploy to Firebase
firebase deploy
```

**3. watchOS App:**
```bash
cd pushed_watch
open pushed_watch.xcodeproj
# Build via Xcode (Cmd+B)
```

## 📋 Shared Contract

All components communicate using a standardized JSON-based notification schema:

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

| Component      | Document                                               | Description                                           |
| -------------- | ------------------------------------------------------ | ----------------------------------------------------- |
| **Governance** | [AGENTS.md](AGENTS.md)                                 | AI agent governance, coding standards, sync protocols |
| **Shared**     | [contract/README.md](contract/README.md)               | Shared schema documentation                           |
| **Android**    | [pushed_android/README.md](pushed_android/README.md)   | Android app documentation                             |
| **Backend**    | [pushed_firebase/README.md](pushed_firebase/README.md) | Firebase orchestrator documentation                   |
| **Watch**      | [pushed_watch/README.md](pushed_watch/README.md)       | watchOS app documentation                             |

## 🧪 Testing

**Android:**
```bash
./gradlew :pushed_android:testDemoDebugUnitTest
```

**Firebase:**
```bash
cd pushed_firebase/functions
npm run test
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
