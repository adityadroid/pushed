# Pushed Watch

watchOS companion app for the Pushed notification bridging system.

## Overview

This app receives and displays notifications forwarded from an Android device. It acts as the **renderer** in the notification bridge architecture.

## Architecture

```
pushed_watch/
├── PushedWatchApp.swift          # App entry point
├── Models/
│   └── PushedNotification.swift  # Shared contract implementation
├── Views/
│   ├── ContentView.swift         # Main navigation container
│   ├── NotificationListView.swift # Notification list with grouping
│   └── NotificationDetailView.swift # Detailed notification view
├── ViewModels/
│   └── NotificationViewModel.swift # Main state holder
├── Services/
│   ├── NotificationSyncService.swift # Android sync communication
│   └── NotificationStore.swift    # Local persistence
└── Complications/
    └── NotificationComplication.swift # Watch face widget
```

## Requirements

- watchOS 11.0+
- Swift 6.2+
- Xcode 16.0+

## Key Features

### Notification Display
- Grouped by date (Today, Yesterday, etc.)
- Category-based icons and colors
- Relative timestamps
- Swipe-to-delete

### Notification Details
- Full notification content
- Available actions
- Metadata display
- Dismiss to Android

### Complications
- Circular: Notification count
- Corner: Bell icon with badge
- Inline: Count text
- Rectangular: Latest notification preview

## Development Guidelines

See [AGENTS.md](../../AGENTS.md) for:
- SwiftUI best practices
- Concurrency guidelines
- Networking efficiency on wearables
- Testing requirements

## Building

```bash
# Open in Xcode
open pushed_watch.xcodeproj

# Build for simulator
xcodebuild -scheme pushed_watch \
    -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)'
```

## Testing

```bash
# Run unit tests
xcodebuild test -scheme pushed_watch \
    -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)'
```
