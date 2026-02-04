# Plan: Create Finalize Task Skill

## Task Metadata
- **Date**: 2026-02-05
- **Task Name**: create-finalize-skill
- **Status**: Completed
- **User Prompt**: "How do I make sure you always do these [governance steps]?"

## Proposed Strategy
### Objective
Create a reusable skill that codifies the "Definition of Done" for the `pushed` repository, ensuring future tasks automatically adhere to governance rules.

### Implementation Steps
1.  Create `skills/finalize-task/SKILL.md`.
2.  Define the checklist: Verification, Documentation (Plan), Git Commit.
3.  Commit the new skill.

## Execution Log
### Files Modified
- `skills/finalize-task/SKILL.md`: Created new skill definition.

### Commands Executed
- `mkdir` to create directory.
- `write_to_file` to populate the skill.
- `ls` to verify structure.

## Outcome & Validation
- **Verification**: Skill file exists.
- **Next Steps**: (Meta) I will now execute this skill to commit *this* change.

## State Update
- **Capability Added**: `finalize-task` is now available for all future sessions.
