# Rule: Task Finalization & Automated Commits

> **Rule ID:** 03
> **Effective Date:** 2026-02-04
> **Version:** 1.0.0
> **Priority:** Critical

---

## Summary

This rule mandates a strict protocol for finalizing tasks. When an AI agent determines that a task is complete, it MUST validate the outcome, and if successful, automatically stage and commit the changes to version control using Conventional Commits.

---

## Requirements

### 1. Finalization Protocol

Upon completing the core logic of a request, the agent MUST perform the following steps in order:

1.  **Validate**: Verify that the changes meet the user's requirements (e.g., build passes, tests pass, documentation updated).
2.  **Check Status**: Run `git status` to identify modified, created, or deleted files.
3.  **Review Diffs**: Briefly review the changes to ensure no extraneous files (like logs or temp files) are included.
4.  **Stage & Commit**: If the changes are correct, proceed to commit.

### 2. Auto-Commit Conditions

Agents are authorized and **required** to auto-commit when:

*   ✅ The user's request has been fully addressed.
*   ✅ The build/tests (if applicable) are successful.
*   ✅ The changes are contained within the scope of the request.

**Exceptions (Do NOT Auto-Commit):**
*   ❌ The user explicitly requested a "dry run" or "review only".
*   ❌ The changes involve sensitive credentials or security configurations (wait for user confirmation).
*   ❌ The task is exploratory or research-based.
*   ❌ There are unresolved errors or the build is failing.

### 3. Commit Message Standards

Commits MUST follow the **Conventional Commits** specification:

```
<type>(<scope>): <subject>
```

**Types:**
*   `feat`: A new feature
*   `fix`: A bug fix
*   `docs`: Documentation only changes
*   `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
*   `refactor`: A code change that neither fixes a bug nor adds a feature
*   `perf`: A code change that improves performance
*   `test`: Adding missing tests or correcting existing tests
*   `chore`: Changes to the build process or auxiliary tools and libraries such as documentation generation

**Scope:**
*   `android`, `firebase`, `watch`, `contract`, `infra`, or `root` (for top-level files).

**Example:**
> `feat(android): implement notification listener service`
> `docs(root): update README architecture diagram`

---

## Workflow Integration

The final step of *any* agent workflow should resemble this pattern:

```yaml
- Step: Verify correctness (build/test)
- Step: Check git status
- Decision:
  - If Correct: `git add .` && `git commit -m "..."`
  - If Incorrect: Fix issues -> specific retry loop
```

---

## Enforcement

*   **Failure to commit** after a successful task is considered a **failure of the agent's core function**.
*   Agents must not leave the repository in a "dirty" state after a completed task unless explicitly instructed.
*   Always report the **Commit Hash** to the user in the final summary.

---

## Related

*   [AGENTS.md](../../AGENTS.md) - Main governance document (Governance section)
*   [01-Traceability](../../.agent/rules/01-traceability-execution-logging.md) - Plan creation rule (often precedes this rule)
