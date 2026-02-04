# Plan: Fix Watch App Compilation Errors

## Task Metadata
- **Date**: 2026-02-05
- **Task Name**: fix-watch-compilation
- **Status**: Completed
- **User Prompt**: Fix compilation errors in pushed_watch app (NotificationViewModel, DeviceRegistrationManager, AuthManager, PushedNotification).

## Proposed Strategy
### Objective
Resolve all Swift compiler errors preventing the `pushed_watch` app from building.

### Implementation Steps
1.  **Analyze Errors**: Read the compiler error logs and identify affected files.
2.  **NotificationViewModel.swift**: Fix the stray markdown characters causing parsing errors.
3.  **DeviceRegistrationManager.swift**: Refactor `lazy var` usage inside `@Observable` class which causes initialization errors.
4.  **AuthManager.swift**: Fix concurrency isolation issues with `deinit`.
5.  **PushedNotification.swift**: Fix incorrect `DecodingError.Context` initialization.
6.  **Verify**: Compile and run checks.

## Execution Log
### Files Modified
- `pushed_watch/pushed_watch/ViewModels/NotificationViewModel.swift`: Removed stray ``` at end of file.
- `pushed_watch/pushed_watch/Firebase/DeviceRegistrationManager.swift`: Removed `lazy` property initialization that conflicted with `@Observable` macro expansion. Replaced stateful `functions` property with direct `Functions.functions()` calls.
- `pushed_watch/pushed_watch/Auth/AuthManager.swift`: Marked `authStateListener` as `nonisolated(unsafe)` to allow access in `deinit`.
- `pushed_watch/pushed_watch/Models/PushedNotification.swift`: Fixed `CodingKeys` vs `codingPath` argument label in error throwing.

### Commands Executed
- `view_file` to inspect errors.
- `replace_file_content` and `multi_replace_file_content` to apply fixes.
- `run_command` to list files.

## Outcome & Validation
- **Build Status**: Success (Confirmed by User).
- **Verification**: User reported app compiles and runs.

## State Update
- **Breaking Changes**: None.
- **Global Context**: `pushed_watch` is now buildable.
