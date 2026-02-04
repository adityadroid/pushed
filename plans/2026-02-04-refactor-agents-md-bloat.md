# Plan: Refactor AGENTS.md Bloat

| Meta            | Details                                                                                                  |
| :-------------- | :------------------------------------------------------------------------------------------------------- |
| **Task Name**   | Refactor AGENTS.md Bloat                                                                                 |
| **Date**        | 2026-02-04                                                                                               |
| **Status**      | 🟢 Completed                                                                                              |
| **User Prompt** | Make AGENTS.md leaner by eliminating bloat (code snippets). Update rules/skills to prevent future bloat. |

## Proposed Strategy

- **Objective**: Remove large code blocks from `AGENTS.md` to transform it into a high-level governance document rather than a code dump.
- **Approach**: 
    1. Strip implementation code from "Specifics" sections.
    2. Replace code with summaries and references.
    3. Update `agent-registry-maintainer` skill and `update-agents-md` workflow to enforce "No Code Bloat".

## Execution Log

| File                                        | Change                                                                      |
| :------------------------------------------ | :-------------------------------------------------------------------------- |
| `AGENTS.md`                                 | Removed Kotlin, Swift, TypeScript code snippets. Added "Anti-Bloat Policy". |
| `skills/agent-registry-maintainer/SKILL.md` | Added "NO CODE SNIPPETS" constraint.                                        |
| `.agent/workflows/update-agents-md.md`      | Added instruction to avoid pasting code snippets.                           |

## Outcome & Validation

- **Final Result**: `AGENTS.md` is significantly smaller and more readable. Governance now explicitly prohibits adding code implementation details.
- **Verification**: Reviewed file contents and verified the "Anti-Bloat Policy" is present.

## State Update

- **Global Context**: `AGENTS.md` is now a leaner source of truth.
- **Breaking Changes**: None to code, but "Breaking" change to Documentation Policy (stricter rule on bloat).
