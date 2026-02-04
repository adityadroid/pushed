---
name: "Requirement Planner"
description: "Deconstructs user requests into actionable plans, identifying the Definition of Done and delegating sub-tasks."
created: "2026-02-04"
version: "1.0.0"
author: "Antigravity"
execution_timing: "Runs immediately upon receiving any user prompt"
---

# Requirement Planner (The Architect)

## Overview
This skill acts as the initial architectural phase for any development task. It ensures that no code is written until a clear, actionable plan is established. It parses user requests, breaks them down into atomic sub-tasks, and assigns them to the appropriate agents or tools.

## Input
| Parameter      | Type   | Description                                                 |
| -------------- | ------ | ----------------------------------------------------------- |
| `user_request` | String | The raw prompt or request provided by the user.             |
| `context`      | Object | Current state of the project, open files, and active plans. |

## Output
| Return Value          | Description                                                                    |
| --------------------- | ------------------------------------------------------------------------------ |
| `implementation_plan` | A markdown document outlining the strategy, sub-tasks, and Definition of Done. |
| `delegation_map`      | A mapping of sub-tasks to specific agents or tools.                            |

## Logic & Steps

### 1. Deconstruct
- **Parse the Request**: Analyze the `user_request` to identify the core objective.
- **Identify Definition of Done**: Clearly define the criteria that must be met for the task to be considered complete (e.g., "All tests pass," "Feature deployed to staging," "Documentation updated").
- **Technical Requirements**: List specific technical constraints or requirements (e.g., "Use Jetpack Compose," "Must be backward compatible").

### 2. Strategic Split
- **Break Down Complexity**: Divide the main request into smaller, atomic sub-tasks.
- **Atomicity Check**: Ensure each sub-task is self-contained and handles one logical unit of work.
- **Dependency Mapping**: Identify dependencies between sub-tasks to determine the execution order.

### 3. Delegate
- **Assign Agents/Tools**: For each sub-task, identify the most suitable agent or tool.
  - *Example*: Assign `run_command` for shell tasks, `write_to_file` for code generation, etc.
- **Create Plan Document**: Generate a plan file in the `/plans` directory (referencing `AGENTS.md` Traceability rules) if the task is significant.

## Constraints
- **No Code First**: Do not proceed to implementation until the plan is established.
- **Clarity**: Ensure the plan is readable and unambiguous.
- **Brevity**: Avoid over-engineering the plan for simple tasks.
