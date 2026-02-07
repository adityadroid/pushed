# AGENTS.md — watchOS (`pushed_watch`)

> **Role:** Renderer  
> **Description:** Receives and displays forwarded notifications  
> Reference: [sample_ios.md](../sample_ios.md)

---

## Core Requirements

- **Target**: watchOS 10.0+
- **Swift Version**: Swift 6.2+
- **UI Framework**: SwiftUI with `@Observable` for state management
- **Concurrency**: Modern Swift concurrency (`async`/`await`, `Actor`)

---

## Technology Constraints

| ✅ Allowed             | ❌ Prohibited           |
| --------------------- | ---------------------- |
| SwiftUI               | WatchKit (legacy)      |
| `@Observable` classes | `ObservableObject`     |
| `NavigationStack`     | `NavigationView`       |
| Swift Concurrency     | Grand Central Dispatch |
| `foregroundStyle()`   | `foregroundColor()`    |

---

## SwiftUI Lifecycle Guidelines

**State Management:**
- Mark `@Observable` classes with `@MainActor`.
- Separate logic (ViewModel) from UI (View).
- Use `Task` and `async/await` for asynchronous operations.

---

## Complications Support

**Complications:**
- Implement `TimelineProvider`.
- Provide placeholder and snapshot entries.
- Efficiently update the timeline to reflect unread counts.

---

## Efficient Networking on Wearable Hardware

**Critical Power Constraints:**

**Power Constraints:**
- ✅ ALWAYS: Batch requests, minimize frequency.
- ✅ ALWAYS: Use background `URLSession` for non-urgent sync.
- ❌ NEVER: Poll frequently; use push notifications instead.

**WatchConnectivity Best Practices:**

- `updateApplicationContext`: For latest state sync (overwrites previous).
- `transferUserInfo`: For queued, guaranteed delivery.
- `sendMessage`: Only for interactive, immediate communication when reachable.

---

## Navigation & Layout

**Navigation Rules:**
- ALWAYS: Use `NavigationStack` with `navigationDestination`.
- PREFER: `containerRelativeFrame()` over `GeometryReader` for responsive sizing.

---

## Build Commands

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

## Testing Guidelines

- Use `Swift Testing` (@Test) for modern unit tests.
- Verify JSON decoding and View Model state changes.

---

## Swift Data Model

Struct `PushedNotification` must conform to `Codable`, `Identifiable`, `Hashable`.
See `PushedNotification.swift`.
