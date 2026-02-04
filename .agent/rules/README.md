# Agent Rules

This directory contains governance rules for AI agents working on this repository. Each rule is defined in a separate markdown file for modularity and easy reference.

## Rule Files

| File                                   | Description                     |
| -------------------------------------- | ------------------------------- |
| `01-traceability-execution-logging.md` | Plan documentation requirements |
| `02-agents-md-governance.md`           | Rules for maintaining AGENTS.md |

## How Rules Are Applied

1. Agents MUST read all rules in this directory before starting significant work
2. Rules are numbered for priority (lower numbers = higher priority)
3. Each rule file is self-contained with examples and enforcement guidelines

## Adding New Rules

1. Create a new file with format: `NN-rule-name.md`
2. Include the standard frontmatter (title, effective date, version)
3. Update this README with the new rule
4. Create a plan document in `/plans` explaining the new rule

## Cross-Reference

The main governance document is [AGENTS.md](../../AGENTS.md), which provides comprehensive platform-specific guidelines. Rules in this directory supplement and formalize key governance requirements.
