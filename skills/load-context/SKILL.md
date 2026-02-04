---
name: "Load Context"
description: "Dynamically load platform-specific context based on the agent's working domain"
created: "2026-02-05"
version: "1.0.0"
author: "AI Agent"
---

# Load Context Skill

## Overview

This skill enables agents to dynamically load the appropriate platform-specific documentation based on which part of the Pushed monorepo they are working on. Instead of loading the entire monolithic `AGENTS.md`, agents load only the relevant context for their current task.

---

## Input

| Parameter | Type   | Required | Description                                                   |
| --------- | ------ | -------- | ------------------------------------------------------------- |
| `domain`  | string | Yes      | One of: `android`, `firebase`, `watch`, `contract`, `general` |

---

## Output

| Output           | Description                                          |
| ---------------- | ---------------------------------------------------- |
| Domain AGENTS.md | Platform-specific rules and guidelines               |
| Standards        | Common standards (if general or cross-platform)      |
| Protocols        | Operational protocols (if general or cross-platform) |

---

## Prerequisites

- Access to the repository root
- File read permissions

---

## Context Map

Use the following table to determine which files to load based on the domain:

| Domain     | Primary File                | Also Load (if applicable) |
| ---------- | --------------------------- | ------------------------- |
| `android`  | `pushed_android/AGENTS.md`  | `contract/AGENTS.md`      |
| `firebase` | `pushed_firebase/AGENTS.md` | `contract/AGENTS.md`      |
| `watch`    | `pushed_watch/AGENTS.md`    | `contract/AGENTS.md`      |
| `contract` | `contract/AGENTS.md`        | —                         |
| `general`  | `docs/STANDARDS.md`         | `docs/PROTOCOLS.md`       |

---

## Steps

### Step 1: Determine Your Domain

Identify the domain based on the files you are working with:

| If working in...        | Domain     |
| ----------------------- | ---------- |
| `pushed_android/`       | `android`  |
| `pushed_firebase/`      | `firebase` |
| `pushed_watch/`         | `watch`    |
| `contract/`             | `contract` |
| Root/docs/plans/skills/ | `general`  |

### Step 2: Load Primary Context

Read the primary AGENTS.md file for your domain:

```bash
# For Android
cat pushed_android/AGENTS.md

# For Firebase
cat pushed_firebase/AGENTS.md

# For watchOS
cat pushed_watch/AGENTS.md

# For Contract
cat contract/AGENTS.md

# For General
cat docs/STANDARDS.md
cat docs/PROTOCOLS.md
```

### Step 3: Load Secondary Context (if needed)

For platform domains (`android`, `firebase`, `watch`), also load the contract if your work involves data models:

```bash
cat contract/AGENTS.md
```

### Step 4: Load Standards & Protocols (if needed)

If your work involves cross-platform considerations or governance:

```bash
cat docs/STANDARDS.md
cat docs/PROTOCOLS.md
```

---

## Error Handling

| Error             | Recovery                                            |
| ----------------- | --------------------------------------------------- |
| File not found    | Check if path is correct; file may have been moved  |
| Unknown domain    | Default to `general` and load STANDARDS + PROTOCOLS |
| Permission denied | Report to user; may need elevated permissions       |

---

## Examples

### Example 1: Android Development Task

```
Domain: android
Files to load:
  1. pushed_android/AGENTS.md (primary)
  2. contract/AGENTS.md (if working with notification models)
```

### Example 2: Firebase Cloud Functions Task

```
Domain: firebase
Files to load:
  1. pushed_firebase/AGENTS.md (primary)
  2. contract/AGENTS.md (if working with Firestore schema)
```

### Example 3: Documentation/Governance Task

```
Domain: general
Files to load:
  1. docs/STANDARDS.md
  2. docs/PROTOCOLS.md
```

---

## Changelog

| Version | Date       | Changes                |
| ------- | ---------- | ---------------------- |
| 1.0.0   | 2026-02-05 | Initial skill creation |
