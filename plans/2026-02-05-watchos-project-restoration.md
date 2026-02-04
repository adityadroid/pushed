# WatchOS App Restructuring & Fixes - Plan

## Overview
This document outlines the work completed to restore, restructure, and fix the `pushed_watch` watchOS application project. The goal was to take a half-complete directory structure and turn it into a valid Xcode project structure that integrates with Firebase for the Pushed notification bridging system.

## Completed Tasks

### 1. Project Structure Restoration
- **Analyzed missing files**: Identified that critical Xcode project configuration files (`Info.plist`, `Entitlements`, `Assets`) were missing.
- **Created `Info.plist`**: Added key configuration file specifying the app as a watchOS application with background notification capabilities.
- **Created Entitlements**: Added `pushed_watch.entitlements` to enable the Push Notifications capability (`aps-environment`).
- **Restored Asset Catalogs**: Created the structure for `Assets.xcassets` (AppIcon, AccentColor) and `Preview Content`.
- **Initialized Test Target**: Created `pushed_watchTests` with a sample modern Swift Testing file.

### 2. Xcode Project Configuration
- **Guidance on Project Creation**: Provided specific instructions to create a new `.xcodeproj` and link the restored files, as binary generation is not possible directly.
- **Resolution of Build Conflicts**:
    - Identified and fixed "Multiple commands produce Info.plist" errors caused by duplicate file references in the "Copy Bundle Resources" phase.
    - Removed the unnecessary iOS Companion App target to create a standalone independent Watch app.
    - Verified the "Watch Only" build settings.

### 3. Dependency Management (Firebase)
- **Firebase SDK Integration**: Instruction provided to add `firebase-ios-sdk` via Swift Package Manager (SPM).
- **Module Resolution Fixes**:
    - Addressed "Unable to find module dependency" errors for `FirebaseFirestore` and `FirebaseMessaging` by explicitly adding them to the target's linked libraries.
    - Fixed `DeviceRegistrationManager.swift` to handle module imports correctly.

### 4. Code Architecture Changes
- **Migration from Firestore to Functions**:
    - **Issue**: `FirebaseFirestore` is not supported natively on watchOS.
    - **Fix**: Refactored `DeviceRegistrationManager.swift` to use `FirebaseFunctions` instead.
    - **Implementation**: Replaced direct database writes with HTTPS Callable Functions (`registerDevice`, `unregisterDevice`, etc.) which is the correct architecture for wearables.

### 5. Swift Concurrency Fixes
- **MainActor Isolation Fix in ViewModel**:
    - **Issue**: `NotificationViewModel` initializer was crashing due to synchronous actor-isolated default arguments.
    - **Fix**: Modified `init` to accept optional `nil` arguments and initialize dependencies synchronously inside the body.
- **Preview Compatibility Fixes**:
    - **Issue**: SwiftUI Previews failed because they tried to pass an `async` function to `.environment()`.
    - **Fix**: Added a synchronous static property `previewInstance` to `NotificationViewModel` and updated all previews to use it.

## Current State & Remaining Work
- **Status**: **DOES NOT COMPILE**. While the structure is fixed and major architectural issues (like removing Firestore) are resolved, the project still requires further debugging to build successfully.
- **Known Issues**:
    - Potential lingering dependency linkage issues with Firebase modules in the Xcode project.
    - `NotificationSyncService` usage in `NotificationViewModel` may need further audit for strict concurrency safety.
    - Integration of the generated files into the `.xcodeproj` relies on manual user steps which may introduce configuration drift.
- **Next Steps**:
    - Verify strict concurrency compliance for `NotificationSyncService`.
    - Debug remaining module linkage errors in Xcode.
    - Deploy the corresponding Firebase Cloud Functions (`registerDevice`, etc.) to the backend to support the new `DeviceRegistrationManager` logic.
