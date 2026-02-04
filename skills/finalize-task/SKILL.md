---
name: Finalize Task
description: Standard procedure for wrapping up a task, ensuring governance compliance (Planning, Testing, Committing).
---

# Finalize Task Skill

> **Goal**: Ensure every task is completed according to the project's governance protocols defined in `docs/PROTOCOLS.md`.

## 1. Verify Verification
- [ ] **Build Check**: Ensure the project compiles.
- [ ] **Lint Check**: Ensure no new linting errors were introduced.
- [ ] **Self-Review**: Briefly check that no extraneous debugging code was left behind.

## 2. Create/Update Plan Document
- Check if a plan document exists in `plans/`.
- **If yes**: Update the "Execution Log" and "Outcome" sections.
- **If no**: Create a new plan file `plans/YYYY-MM-DD-task-name.md`.
    - **Template**:
      ```markdown
      # Plan: [Task Name]
      
      ## Task Metadata
      - **Date**: [YYYY-MM-DD]
      - **Status**: Completed
      - **User Prompt**: [Summary]
      
      ## Execution Log
      - **Files Modified**: [List of files]
      - **Commands Executed**: [Summary]
      
      ## Outcome
      - **Verification**: [How was it tested?]
      - **Status**: Success
      ```

## 3. Git Operations (Automated)
- [ ] **Stage**: Run `git add -A`
- [ ] **Status**: Run `git status` to verify file list.
- [ ] **Commit**: Run `git commit -m "type(scope): description"`
    - **Type**: `feat`, `fix`, `docs`, `refactor`, `style`, `test`, `chore`
    - **Scope**: `android`, `watch`, `firebase`, `contract`, `infra`

## 4. Final Report
- Output the commit hash.
- Confirm that governance steps are complete.
