# AGENTS.md — Pushed Notification Bridge Monorepo

> **Version:** 2.0.0 | **Last Updated:** 2026-02-05

---

## ⚠️ MANDATORY BOOTSTRAP — READ FIRST

> **CRITICAL**: Before starting any task, you MUST load context for your specific domain.

**Execute the `load-context` skill immediately:**

1. **Identify your domain** based on what files you're working with:
   - Working in `pushed_android/` → Domain: **android**
   - Working in `pushed_firebase/` → Domain: **firebase**
   - Working in `pushed_watch/` → Domain: **watch**
   - Working in `contract/` → Domain: **contract**
   - Working elsewhere → Domain: **general**

2. **Read the `load-context` skill**: `skills/load-context/SKILL.md`

3. **Load Standards & Protocols**: Ensure `docs/STANDARDS.md` and `docs/PROTOCOLS.md` are loaded.
4. **Load domain-specific AGENTS.md** from the Context Map below.

---

## 📍 Context Map

| Domain     | Primary Documentation                                    | Secondary (if needed)                      |
| ---------- | -------------------------------------------------------- | ------------------------------------------ |
| `android`  | [`pushed_android/AGENTS.md`](pushed_android/AGENTS.md)   | [`contract/AGENTS.md`](contract/AGENTS.md) |
| `firebase` | [`pushed_firebase/AGENTS.md`](pushed_firebase/AGENTS.md) | [`contract/AGENTS.md`](contract/AGENTS.md) |
| `watch`    | [`pushed_watch/AGENTS.md`](pushed_watch/AGENTS.md)       | [`contract/AGENTS.md`](contract/AGENTS.md) |
| `contract` | [`contract/AGENTS.md`](contract/AGENTS.md)               | —                                          |
| `general`  | —                                                        | —                                          |

> **Note**: `docs/STANDARDS.md` and `docs/PROTOCOLS.md` are **Global/Base Context** and MUST be loaded for ALL domains.

---

## 🏗️ Project Overview

**Pushed** is a notification bridging system consisting of:

| App               | Platform     | Role             | Description                                                       |
| ----------------- | ------------ | ---------------- | ----------------------------------------------------------------- |
| `pushed_android`  | Android      | **Listener**     | Intercepts system notifications via `NotificationListenerService` |
| `pushed_firebase` | Firebase/GCP | **Orchestrator** | Middleware for auth, data sync, and push notification dispatch    |
| `pushed_watch`    | watchOS      | **Renderer**     | Receives and displays forwarded notifications                     |

### Architecture

```
┌─────────────────────┐     ┌─────────────────────────┐     ┌─────────────────────┐
│   pushed_android    │     │     pushed_firebase     │     │    pushed_watch     │
│   ───────────────   │     │    ───────────────      │     │   ───────────────   │
│   • Intercept       │     │   • Authenticate        │     │   • Receive         │
│   • Filter          │────►│   • Queue & Store       │────►│   • Display         │
│   • Transform       │     │   • Dispatch via FCM    │     │   • Manage          │
│   • Write to DB     │     │   • Device Registry     │     │   • Archive         │
└─────────────────────┘     └─────────────────────────┘     └─────────────────────┘
        LISTENER                   ORCHESTRATOR                    RENDERER

                            Shared Contract (JSON Schema)
```

### Data Flow

1. Android device receives notification
2. pushed_android transforms and writes to Firestore
3. pushed_firebase Cloud Function triggers on write
4. Function fetches registered watchOS devices
5. FCM dispatches push notification to Apple Watch
6. pushed_watch displays notification via APNs → FCM bridge

---

## 📚 Documentation Index

| Category      | Document                                                 | Description                           |
| ------------- | -------------------------------------------------------- | ------------------------------------- |
| **Standards** | [`docs/STANDARDS.md`](docs/STANDARDS.md)                 | Versioning, commits, code review      |
| **Protocols** | [`docs/PROTOCOLS.md`](docs/PROTOCOLS.md)                 | Traceability, skills, governance      |
| **Android**   | [`pushed_android/AGENTS.md`](pushed_android/AGENTS.md)   | Android-specific rules                |
| **Firebase**  | [`pushed_firebase/AGENTS.md`](pushed_firebase/AGENTS.md) | Firebase-specific rules               |
| **watchOS**   | [`pushed_watch/AGENTS.md`](pushed_watch/AGENTS.md)       | watchOS-specific rules                |
| **Contract**  | [`contract/AGENTS.md`](contract/AGENTS.md)               | Shared payload schema                 |
| **Plans**     | [`plans/`](plans/)                                       | Task documentation and execution logs |
| **Skills**    | [`skills/`](skills/)                                     | Reusable agent workflows              |

---

## ⚡ Quick Reference

### Commit Format
```
<type>(<scope>): <description>
```
Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`  
Scopes: `android`, `firebase`, `watch`, `contract`, `infra`, `agents`

### Key Rules

- ✅ Create plan documents for significant tasks → `plans/YYYY-MM-DD-task-name.md`
- ✅ Use domain-specific AGENTS.md for platform rules
- ✅ Follow Conventional Commits specification
- ✅ Auto-commit when all criteria met (builds pass, tests pass, lint clean)
- ❌ Never paste code snippets into AGENTS.md (use links instead)
- ❌ No direct commits to `main` branch

---

## 🔄 Change Log

| Version | Date       | Changes                                                            |
| ------- | ---------- | ------------------------------------------------------------------ |
| 2.0.0   | 2026-02-05 | Major refactor: Split into federated domain-specific documentation |
| 1.4.0   | 2026-02-04 | Added Proactive Skill Acquisition protocol                         |
| 1.3.0   | 2026-02-04 | Added Mandatory Synchronization Rule                               |
| 1.2.0   | 2026-02-04 | Added Firebase Specifics section                                   |
| 1.1.0   | 2026-02-04 | Added Traceability & Execution Logging governance                  |
| 1.0.0   | 2026-02-04 | Initial AGENTS.md creation                                         |

---

*This document is a Hub. For detailed rules, load context for your specific domain.*
