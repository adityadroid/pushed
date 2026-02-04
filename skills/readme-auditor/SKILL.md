---
name: "README Auditor"
description: "Reviews code changes to ensure documentation (README.md) remains in sync with the codebase."
created: "2026-02-04"
version: "1.0.0"
author: "Antigravity"
execution_timing: "Runs upon completion of any sub-task or code change"
---

# README Auditor (The Documentarian)

## Overview
This skill ensures that project documentation matches the actual state of the code. It scans diffs for user-facing or developer-critical changes and updates the `README.md` file accordingly.

## Input
| Parameter    | Type          | Description                                                 |
| ------------ | ------------- | ----------------------------------------------------------- |
| `diffs`      | String/Object | The set of changes made during the recent task or sub-task. |
| `file_paths` | List          | A list of modified files.                                   |

## Output
| Return Value       | Description |
| ------------------ | ----------- |
| `readme_update`    | Boolean     | True if the README was updated, False otherwise.   |
| `change_log_entry` | String      | A proposed entry for the changelog, if applicable. |

## Logic & Steps

### 1. Review
- **Scan Diffs**: Analyze the code changes provided in `diffs`.
- **Target Areas**: Look specifically for changes in:
  - **Architecture**: New modules, components, or structural changes.
  - **Installation/Setup**: Changes to build commands, dependencies, or configuration (env vars).
  - **Public API**: Changes to exposed endpoints, interfaces, or usage patterns.

### 2. Judge
- **Classify Change**: Determine if the change is:
  - `User-Facing`: Affects how a user interacts with the system (REQUIRES update).
  - `Developer-Critical`: Affects how a developer builds/runs the system (REQUIRES update).
  - `Internal/Trivial`: Internal refactors, formatting, private logic (IGNORES update).

### 3. Action
- **Update README**: If classified as `User-Facing` or `Developer-Critical`, modify the `README.md` to reflect the new state.
- **Verify Consistency**: Ensure the new documentation doesn't contradict existing sections.

## Constraints
- **Clarity & Brevity**: Updates should be concise.
- **Avoid Redundancy**: Do not document internal implementation details that don't affect usage.
- **No Trivial Updates**: Skip updates for minor refactors or "chore" tasks that don't change behavior.
