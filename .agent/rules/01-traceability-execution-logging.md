# Rule: Traceability & Execution Logging

> **Rule ID:** 01  
> **Effective Date:** 2026-02-04  
> **Version:** 1.0.0  
> **Priority:** High

---

## Summary

Every significant task performed by an AI agent MUST be documented in the `/plans` directory at the root of this repository.

---

## Requirements

### Plan Directory Structure

```
plans/
├── template.md                    # Standard template for all plans
├── YYYY-MM-DD-task-name.md       # Individual plan documents
└── ...
```

### Naming Convention

```
plans/YYYY-MM-DD-task-name.md
```

**Example:** `plans/2026-02-04-implement-notification-listener.md`

---

## Required Sections

Each plan document MUST contain:

### 1. Task Metadata

| Field             | Description                                         |
| ----------------- | --------------------------------------------------- |
| **Task Name**     | Brief descriptive name                              |
| **Date**          | YYYY-MM-DD format                                   |
| **Agent Session** | Session identifier (if available)                   |
| **Status**        | 🟡 Planning / 🔵 In Progress / 🟢 Completed / 🔴 Failed |
| **User Prompt**   | The exact instruction provided by the user          |

### 2. Proposed Strategy

- **Objective**: What this task aims to achieve
- **Architectural Overview**: High-level approach and design decisions
- **Implementation Steps**: Ordered list of planned actions
- **Dependencies**: Prerequisites and external requirements

### 3. Execution Log

- **Files Modified**: Table of created/modified/deleted files with descriptions
- **New Dependencies**: Any libraries, packages, or services added
- **Boilerplate Generated**: Templates and scaffolding created
- **Commands Executed**: Significant commands run during execution

### 4. Outcome & Validation

- **Final Result**: Summary of what was accomplished
- **Verification Steps**: How to verify the implementation works
- **Known Limitations**: Edge cases, incomplete functionality, or technical debt
- **Test Results**: Status of unit tests, builds, and manual testing

### 5. State Update

- **Global Context Changes**: Changes that affect the entire project
- **Breaking Changes**: Schema or API changes requiring migration
- **Cross-App Impact**: Effects on other applications in the monorepo
- **Configuration Changes**: Environment variables, config files, or settings

---

## Directives

### Atomicity

Each plan document MUST cover **one logical feature or task**.

✅ **Good (Atomic):**
- "Implement Android Notification Listener"
- "Add SwiftUI Notification Detail View"
- "Update Contract Schema to v1.1.0"

❌ **Bad (Non-Atomic):**
- "Implement entire notification system"
- "Various fixes and improvements"

### Cross-App Impact & Breaking Changes

When a change affects multiple components, explicitly flag it:

```markdown
> ⚠️ **Breaking Change Alert**: [Description]

| Component Affected | Change        | Migration Path   |
| ------------------ | ------------- | ---------------- |
| `pushed_android`   | [Description] | [How to migrate] |
| `pushed_firebase`  | [Description] | [How to migrate] |
| `pushed_watch`     | [Description] | [How to migrate] |
```

### Persistence & Continuity

Before starting any new work, agents MUST:

1. **Check the `/plans` directory** for existing plans related to the task
2. **Review recent plans** to understand current project state
3. **Reference prior plans** when building on previous work
4. **Update existing plans** if continuing incomplete work

---

## When to Create a Plan

| Scenario                           | Plan Required?        |
| ---------------------------------- | --------------------- |
| New feature implementation         | ✅ Yes                 |
| Significant refactoring            | ✅ Yes                 |
| Schema or API changes              | ✅ Yes                 |
| Bug fix with multiple file changes | ✅ Yes                 |
| Simple typo fix                    | ❌ No                  |
| Updating dependencies              | ⚠️ Only if breaking    |
| Documentation updates              | ⚠️ Only if significant |

---

## Template

Use the template at `plans/template.md` as the starting point for all plan documents.

---

## Enforcement

- All PRs involving significant changes SHOULD reference their plan document
- Code reviewers MAY request a plan document for undocumented changes
- Plans serve as permanent documentation and should be maintained

---

## Related

- [AGENTS.md](../../AGENTS.md) - Main governance document
- [plans/template.md](../../plans/template.md) - Plan template
