# Rule: AGENTS.md Governance

> **Rule ID:** 02  
> **Effective Date:** 2026-02-04  
> **Version:** 1.0.0  
> **Priority:** High

---

## Summary

This rule establishes the governance for maintaining, updating, and managing the AGENTS.md file itself.

---

## Document Ownership

- AGENTS.md is the **single source of truth** for all AI agent governance in this repository
- Changes to this document affect all agents working on this codebase
- All contributors (human and AI) MUST adhere to the rules defined there

---

## Update Requirements

Before modifying AGENTS.md, agents MUST:

1. **Create a plan document** in `/plans` for the proposed changes
2. **Justify the change** with clear rationale
3. **Consider cross-platform impact** — rules often affect multiple apps
4. **Maintain backward compatibility** when possible

---

## Versioning Rules

AGENTS.md follows semantic versioning for its own changes:

| Change Type       | Version Bump | Examples                                                  |
| ----------------- | ------------ | --------------------------------------------------------- |
| **Major** (X.0.0) | Breaking     | Removing a required section, changing mandatory protocols |
| **Minor** (x.Y.0) | Additive     | Adding new governance rules, new platform support         |
| **Patch** (x.y.Z) | Fixes        | Typo fixes, formatting improvements, examples             |

---

## Change Log Requirements

Every update to AGENTS.md MUST:

1. **Increment the version** appropriately in the Change Log
2. **Add a dated entry** describing the change
3. **Reference the plan document** if applicable

---

## Adding New Platform/Component Sections

When adding support for a new platform (e.g., `pushed_firebase`):

1. **Add to Table of Contents** — Insert in appropriate order
2. **Update Project Overview** — Add to the architecture diagram and app table
3. **Add Commit Scope** — Register new scope in Common Standards
4. **Create Full Section** — Document technology stack, guidelines, and commands
5. **Update Breaking Changes Template** — Include new component in cross-app impact tables

---

## Permission Boundaries

### Prohibited Changes (Require Human Approval)

- ❌ Removing existing governance rules entirely
- ❌ Weakening security or privacy requirements
- ❌ Changing versioning policies
- ❌ Modifying the contract schema without coordination
- ❌ Removing mandatory plan documentation requirements

### Allowed Changes by Agents

- ✅ Adding new platform/component sections
- ✅ Clarifying existing rules with examples
- ✅ Fixing typos and formatting
- ✅ Adding new best practices (non-breaking)
- ✅ Updating technology stack recommendations
- ✅ Expanding the Change Log

---

## Conflict Resolution

If two rules in AGENTS.md conflict:

1. **More specific rule wins** over general rules
2. **Security rules** take precedence over convenience
3. **Contract integrity** takes precedence over single-platform needs
4. When in doubt, **create a plan document** to propose resolution

---

## Review Checklist

Before committing changes to AGENTS.md:

- [ ] Version number incremented appropriately
- [ ] Change Log updated with description
- [ ] Table of Contents reflects any new sections
- [ ] Cross-references and links are valid
- [ ] No breaking changes without migration path
- [ ] Plan document created (if significant change)

---

## Related

- [AGENTS.md](../../AGENTS.md) - Main governance document
- [Rule 01: Traceability](./01-traceability-execution-logging.md) - Plan documentation requirements
