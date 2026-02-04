# 🧠 Skills Directory

> Reusable, well-documented patterns for common and complex tasks.

## What Are Skills?

Skills are formalized, reusable workflows that encapsulate repetitive or complex logic patterns. Instead of re-implementing solutions for common tasks, agents can leverage existing skills to ensure consistency, reduce errors, and improve efficiency.

## Directory Structure

```
skills/
├── README.md           # This file - overview and guidelines
├── TEMPLATE.md         # Standard template for creating new skills
└── [skill-name]/       # Individual skill folders
    ├── SKILL.md        # Main instruction file (required)
    ├── scripts/        # Helper scripts (optional)
    ├── examples/       # Reference implementations (optional)
    └── resources/      # Templates, assets, configs (optional)
```

## Using Skills

Before starting a task, agents should:

1. **Check this directory** for relevant existing skills
2. **Read `SKILL.md`** to understand the skill's capabilities and requirements
3. **Follow the documented steps** exactly as specified
4. **Reference examples** when available

```bash
# Quick check for available skills
ls skills/
```

## Creating New Skills

Skills should be created when:

- ✅ A task requires more than three steps
- ✅ A task is likely to be repeated in future sessions
- ✅ A complex pattern benefits from standardization
- ✅ Knowledge should be preserved across agent sessions

### Creation Checklist

- [ ] Create skill folder with descriptive name (kebab-case)
- [ ] Write SKILL.md with:
  - [ ] YAML frontmatter (name, description, version)
  - [ ] Clear input/output documentation
  - [ ] Step-by-step instructions
  - [ ] Error handling guidance
- [ ] Add examples for non-trivial skills
- [ ] Test the skill before finalizing
- [ ] Notify user of new skill creation

### Skill Naming Convention

```
[domain]-[action]-[target]

Examples:
- firebase-deploy-functions
- android-generate-model
- contract-validate-schema
- git-create-feature-branch
```

## Skill Categories

| Category            | Description                     | Example Skills                     |
| ------------------- | ------------------------------- | ---------------------------------- |
| **Build**           | Compilation and packaging       | android-build, ios-archive         |
| **Deploy**          | Deployment workflows            | firebase-deploy, testflight-upload |
| **Generate**        | Code generation and scaffolding | generate-model, create-viewmodel   |
| **Validate**        | Testing and validation          | run-tests, lint-code               |
| **Documentation**   | Doc generation and updates      | update-readme, generate-api-docs   |
| **Synchronization** | Cross-platform data sync        | sync-schema, migrate-contract      |

## Quality Standards

All skills must:

1. **Be Self-Documenting**: Include clear docstrings for inputs, outputs, and use cases
2. **Be Modular**: Focus on a single, well-defined task
3. **Handle Errors Gracefully**: Document failure modes and recovery strategies
4. **Be Tested**: Include verification steps to confirm success
5. **Be Versioned**: Track changes in a changelog

## Governance

This directory is governed by the **Proactive Skill Acquisition** section in `AGENTS.md`. Agents are authorized to:

- Create new skills proactively when patterns are identified
- Update existing skills to improve quality or add capabilities
- Deprecate skills that are no longer relevant

All significant skill additions should be logged in the `/plans` directory with appropriate documentation.

---

*Last Updated: 2026-02-04*
