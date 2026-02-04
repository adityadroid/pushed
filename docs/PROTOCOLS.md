# Protocols & Governance

> This document defines operational protocols, traceability requirements, skill development, and AGENTS.md governance rules.

---

## Traceability & Execution Logging

> **Effective Date:** 2026-02-04

Every significant task performed by an AI agent MUST be documented in the `/plans` directory. This ensures continuity across agent sessions and maintains a complete audit trail.

### Plan Directory Structure

```
plans/
├── template.md                  # Standard template for all plans
├── YYYY-MM-DD-task-name.md      # Individual plan documents
└── ...
```

### Required Documentation

For every significant task, create a Markdown file:
```
plans/YYYY-MM-DD-task-name.md
```

Each plan document MUST contain:
1. **Task Metadata**: Name, date, status, user prompt
2. **Proposed Strategy**: Objective, overview, implementation steps
3. **Execution Log**: Files modified, dependencies, commands executed
4. **Outcome & Validation**: Results, verification steps, known limitations
5. **State Update**: Global context changes, breaking changes

### When to Create a Plan

| Scenario                           | Plan Required? |
| ---------------------------------- | -------------- |
| New feature implementation         | ✅ Yes          |
| Significant refactoring            | ✅ Yes          |
| Schema or API changes              | ✅ Yes          |
| Bug fix with multiple file changes | ✅ Yes          |
| Simple typo fix                    | ❌ No           |
| Updating dependencies              | ⚠️ If breaking  |

---

## Proactive Skill Acquisition

> **Effective Date:** 2026-02-04

### Skills Directory Structure

```
skills/
├── README.md           # Overview and guidelines
├── TEMPLATE.md         # Standard template for new skills
└── [skill-name]/       # Individual skill folders
    ├── SKILL.md        # Main instruction file (required)
    ├── scripts/        # Helper scripts (optional)
    └── examples/       # Reference implementations (optional)
```

### Pattern Recognition Criteria

Create a new skill when:
- Task requires more than 3 sequential steps
- Task is likely to be repeated in future sessions
- Task involves steps that are easy to forget
- Knowledge would be lost between sessions without documentation

### Skill Quality Standards

| Standard           | Requirement                                        |
| ------------------ | -------------------------------------------------- |
| Single Purpose     | Each skill focuses on one well-defined task        |
| Testable           | Includes verification steps                        |
| Idempotent         | Running multiple times produces consistent results |
| Version-Controlled | Changes tracked in skill changelog                 |

---

## AGENTS.md Governance

> **Effective Date:** 2026-02-04

### Mandatory Synchronization Rule

> ⚠️ **CRITICAL**: When the repository undergoes a **major change**, `AGENTS.md` MUST be updated.

**Major changes include:**
- New component/app added
- Architecture shift
- Technology migration
- Protocol/schema changes
- Platform addition

### Anti-Bloat Policy

> ⚠️ **NO CODE SNIPPETS**: `AGENTS.md` is a high-level governance document.
>
> **Instead:**
> - Link to source files
> - Reference sample documentation
> - Provide high-level summaries

### Prohibited Changes (require human approval)

- ❌ Removing existing governance rules
- ❌ Weakening security/privacy requirements
- ❌ Changing versioning policies
- ❌ Modifying contract schema without coordination

### Allowed Changes by Agents

- ✅ Adding new platform/component sections
- ✅ Clarifying existing rules with examples
- ✅ Fixing typos and formatting
- ✅ Adding new best practices (non-breaking)

---

## Operational Protocols

### Task Finalization

Agents MUST independently determine when a task is complete:

| Criterion              | Requirement                           |
| ---------------------- | ------------------------------------- |
| Requirements Met       | All aspects of user request addressed |
| Build Success          | Project compiles without errors       |
| Tests Passing          | All relevant tests pass               |
| Linting Clean          | No blocking lint errors               |
| Documentation Updated  | Relevant docs reflect the changes     |
| Plan Document Complete | Execution log and outcome filled in   |

### Automated Commits

Upon task completion, agents MUST:
1. Stage changes: `git add -A`
2. Verify staged files: `git status`
3. Execute commit with conventional message

### Post-Commit Verification

After committing, agents MUST provide:
- Commit hash
- Summary of changes
- Files modified
- Build/test status
