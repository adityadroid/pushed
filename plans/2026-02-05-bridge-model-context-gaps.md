# Plan: Bridge Model Context Gaps

> **State:** COMPLETED
> **Created:** 2026-02-05

## 1. Task Metadata

- **User Request:** "This project currently uses multiple models (claude code, gemini 3 Pro, Codex 5.2) to run agents on it. I believe it currently does not follow the required file and directory structure for rules, skills and other files to be read by all three models. Your job is to bridge this gap." following up with refinements to use symlinks for Claude.
- **Goal:** Ensure all agentic models (Claude, Gemini, Codex) can access the project's governance and context rules (`AGENTS.md` and `.agent/rules`) effectively.

## 2. Proposed Strategy

### Objective
Standardize how different AI models load context and rules, ensuring the "Federated Documentation" structure of `AGENTS.md` v2.0.0 is respected.

### Implementation Steps

1.  **Analyze Current State**:
    *   `AGENTS.md`: The central hub.
    *   `.gemini/settings.json`: Already points to `AGENTS.md`.
    *   `CLAUDE.md`: Minimal pointer.
    *   Codex/Cursor: No specific config.

2.  **Refine Claude Integration**:
    *   Create a symlink from `.claude/rules` to `.agent/rules`.
    *   This allows Claude to auto-ingest detailed governance rules without cluttering `CLAUDE.md` or the root directory.
    *   Keep `CLAUDE.md` minimal (`@AGENTS.md`) as it supports the `@` import syntax.

3.  **Refine Codex/Cursor Integration**:
    *   Determine that `.cursorrules` is unnecessary because Cursor natively supports `AGENTS.md` (as per user instruction).
    *   Rely on `AGENTS.md` as the single source of truth.

4.  **Verification**:
    *   Gemini: Config verified.
    *   Claude: Symlink established.
    *   Codex/Cursor: Relies on standard `AGENTS.md`.

## 3. Execution Log

- **Files Modified**:
    - Created `.claude/rules` (symlink to `.agent/rules`).
    - (Temporary: Created/Deleted `.cursorrules`).
    - (Temporary: Modified/Reverted `CLAUDE.md`).
    - (Temporary: Modified/Reverted `skills/load-context/SKILL.md`).

- **Commands Executed**:
    - `ln -s "$(pwd)/.agent/rules" .claude/rules`
    - `rm .cursorrules`

## 4. Outcome & Validation

- **Claude**: Now has direct access to `.agent/rules` via the `.claude/rules` symlink, ensuring strict governance compliance alongside `AGENTS.md` context.
- **Gemini**: Continues to use `AGENTS.md` via `.gemini/settings.json`.
- **Codex**: Uses `AGENTS.md` directly.
- **Governance**: Structure remains clean with no duplicated rule files.

## 5. State Update

- **Global Context**: The repo is now "Model Agnostic" regarding rule ingestion.
- **Breaking Changes**: None.
