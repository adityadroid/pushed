# Plan: Fix Firebase Functions Linting and Deployment

> **Template Version:** 1.0.0
> **Last Updated:** 2026-02-05

---

## 📋 Task Metadata

| Field             | Value                                                     |
| ----------------- | --------------------------------------------------------- |
| **Task Name**     | Fix Firebase Functions Linting and Deployment             |
| **Date**          | 2026-02-05                                                |
| **Agent Session** | Current                                                   |
| **Status**        | 🟢 Completed (Code Fixes) / 🔴 Deployment Blocked (Billing) |

### User Prompt/Instruction

```
Fix this
(referring to 'eslint: command not found' and subsequent lint errors during firebase deploy)
```

---

## 🎯 Proposed Strategy

### Objective

Resolve the `eslint: command not found` error and subsequent linting issues in the `pushed_firebase/functions` directory to allow for successful compilation and deployment.

### Architectural Overview

The issue stems from missing dependencies in the `functions` directory and strict linting rules. The strategy involves:
1.  Installing dependencies (`npm install`).
2.  Fixing lint/style errors (`eslint --fix`).
3.  Ensuring the environment is clean (`.gitignore` updates).

### Implementation Steps

1.  **Step 1**: Install NPM dependencies in `pushed_firebase/functions`.
2.  **Step 2**: Run `npm run lint:fix` to resolve auto-fixable lint errors.
3.  **Step 3**: Clean up build artifacts and configure `.gitignore`.
4.  **Step 4**: Commit changes.

### Dependencies & Prerequisites

-   [x] Node.js & NPM
-   [x] Firebase CLI

---

## 📝 Execution Log

### Files Modified

| File Path                                        | Change Type | Description                            |
| ------------------------------------------------ | ----------- | -------------------------------------- |
| `pushed_firebase/functions/package-lock.json`    | Created     | NPM lockfile generated after install   |
| `pushed_firebase/functions/.gitignore`           | Created     | Added to ignore `lib/` build artifacts |
| `pushed_firebase/functions/src/index.ts`         | Modified    | Auto-fixed linting errors              |
| `pushed_firebase/functions/src/notifications.ts` | Modified    | Auto-fixed linting errors              |
| `pushed_firebase/.firebaserc`                    | Modified    | Updated by Firebase tooling            |

### Commands Executed

```bash
cd pushed_firebase/functions
npm install --cache ./.npm_cache # Workaround for permissions issue
npm run lint:fix
git add .
git commit -m "fix(firebase): resolve linting errors and update dependencies"
```

---

## ✅ Outcome & Validation

### Final Result

-   Dependencies successfully installed.
-   Linting errors resolved (395 errors fixed).
-   `npm run build` passes locally.
-   **Deployment Failure**: `firebase deploy` failed because the project requires the **Blaze (Pay-as-you-go)** plan to enable `cloudbuild.googleapis.com` and `cloudfunctions.googleapis.com`.

### Verification Steps

1.  **Check Lint**: `npm run lint` -> Output: Warnings only (TS version mismatch), no errors.
2.  **Check Build**: `npm run build` -> Output: Success.
3.  **Deploy**: `firebase deploy` -> Output: Error (Billing plan requirement).

### Known Limitations

-   **Billing Requirement**: Deployment is currently impossible without upgrading the Firebase project to the Blaze plan.

### Test Results

| Test Type  | Status | Notes                                        |
| ---------- | ------ | -------------------------------------------- |
| Lint Check | ✅      | All errors fixed                             |
| Build      | ✅      | Compiles successfully                        |
| Deployment | 🔴      | Blocked by Google Cloud billing requirements |

---

## 🔄 State Update

### Global Context Changes

-   `pushed_firebase/functions` now has `node_modules` (if not ignored) and a `package-lock.json`.
-   Codebase is compliant with the configured ESLint rules.

### Breaking Changes

None.

### Cross-App Impact

-   **pushed_android**: No impact
-   **pushed_watch**: No impact
-   **contract**: No impact

### Configuration Changes

-   New `.gitignore` in functions directory.

### Documentation Updates Required

-   [ ] None

---

## 📌 Notes for Future Agents

-   **Billing Upgrade Needed**: Any future task involving deploying these functions will FAIL until the user upgrades the Firebase project to Blaze.
-   **Permissions**: There are some permission issues with the global `.npm` cache on this machine. Use local cache or `sudo` (if available/safe) for npm operations if needed.

---

*This plan follows the Traceability & Execution Logging protocol defined in [AGENTS.md](../AGENTS.md)*
