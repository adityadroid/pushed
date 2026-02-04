---
name: "Agent Registry Maintainer"
description: "Monitors and updates AGENTS.md when agent capabilities, personas, or system rules evolve."
created: "2026-02-04"
version: "1.0.0"
author: "Antigravity"
execution_timing: "Runs upon completion of tasks involving agent logic or configuration"
---

# Agent Registry Maintainer (The Librarian)

## Overview
This skill acts as the custodian of the `AGENTS.md` file. It encapsulates the governance rules for keeping the agent registry and system documentation up to date. It ensures that any evolution in agent personas, tool access, or system-wide protocols is immediately reflected in the governance documentation.

## Input
| Parameter              | Type    | Description                                           |
| ---------------------- | ------- | ----------------------------------------------------- |
| `task_outcome`         | Object  | The result of the completed task.                     |
| `modified_files`       | List    | Files changed during the task.                        |
| `agent_config_changes` | Boolean | True if agent prompts, tools, or roles were modified. |

## Output
| Return Value       | Description |
| ------------------ | ----------- |
| `agents_md_update` | Boolean     | True if AGENTS.md was updated.                      |
| `version_bump`     | String      | The new version number for AGENTS.md (e.g., 1.1.0). |

## Logic & Steps

### 1. Extraction (Governance Integration)
- **Reference AGENTS.md Governance**: This skill implements the "Mandatory Synchronization Rule" defined in `AGENTS.md`.
- **Identify Major Changes**: Check if the task involved:
  - New Components or Platforms.
  - Architecture Shifts.
  - Technology Migrations.
  - Protocol or Schema Changes.
  - Changes to "Skills" or "Workflows".

### 2. Review
- **Monitor Metadata**: Specifically check for changes to:
  - Agent Personas (Roles, Responsibilities).
  - Tool Access (New tools added, permissions changed).
  - System Prompts (New context or constraints).
- **Check Consistency**: Ensure that new capabilities (like new skills added to `/skills`) are registered in `AGENTS.md` if required (e.g., under "11. Proactive Skill Acquisition" or a new section).

### 3. Action
- **Update AGENTS.md**:
  - **Increment Version**: Follow semantic versioning (Major/Minor/Patch) as defined in the governance section.
  - **Log Change**: Add an entry to the "Change Log" at the bottom of `AGENTS.md`.
  - **Reflect State**: Modify the relevant sections (e.g., "Project Overview", "Technology Stack", "Operational Protocols") to match the new reality.

## Constraints
- **Clarity and Brevity**: Updates should be precise.
- **Avoid Redundant Updates**: Do not update `AGENTS.md` for trivial refactors that do not change the functional footprint or governance rules.
- **Strict Adherence**: Follow the "Allow Changes by Agents" and "Prohibited Changes" rules in `AGENTS.md`.
- **NO CODE SNIPPETS**: Never add implementation code, JSON schemas, or config files to `AGENTS.md`. Use high-level descriptions or links to source/sample files instead.
