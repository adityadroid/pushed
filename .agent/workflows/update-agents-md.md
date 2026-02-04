---
description: Update AGENTS.md when major architectural changes occur in the repository
---

# Update AGENTS.md Workflow

This workflow should be triggered whenever a major change occurs in the repository that affects the project's architecture, technology stack, or component structure.

## When to Use This Workflow

Use this workflow when:
- Adding a new app/component to the monorepo
- Changing core architecture patterns  
- Introducing new technology or framework
- Modifying the shared contract schema
- Adding new build commands or workflows
- Making breaking changes to any platform

## Steps

1. **Identify the type of change** by reviewing the Mandatory Synchronization Rule in AGENTS.md:
   - New Component
   - Architecture Shift
   - Technology Migration
   - Protocol Change
   - Schema Evolution
   - Platform Addition

2. **Update the Table of Contents** if adding new sections:
   - Open `/AGENTS.md`
   - Add new entry in the numbered list
   - Ensure proper ordering

3. **Update Project Overview** if architecture changes:
   - Modify the app table to add/update entries
   - Update the architecture diagram (ASCII art)
   - Update the data flow section if applicable

4. **Add commit scope** in Common Standards (if new component):
   - Add new scope to the `**Scopes:**` list
   - Example: `- \`firebase\`: Changes to \`pushed_firebase\``

5. **Create/Update Specifics Section** for the affected component:
   - Follow the section template from AGENTS.md Governance
   - Include: Role, Technology Stack, Project Structure, Guidelines, Build Commands
   - **DO NOT** paste code snippets. Use links to source files or high-level summaries.

6. **Update the Change Log**:
   - Increment version appropriately (MAJOR.MINOR.PATCH)
   - Add dated entry with description
   - Reference plan document if applicable

7. **Create plan document** in `/plans` directory:
   - Use template from `plans/template.md`
   - Document the changes made to AGENTS.md

// turbo
8. **Verify build status**:
   ```bash
   # For Android
   ./gradlew :pushed_android:assembleDemoDebug
   
   # For Firebase
   cd pushed_firebase/functions && npm run build
   
   # For watchOS
   xcodebuild -project pushed_watch/pushed_watch.xcodeproj -scheme pushed_watch build
   ```

// turbo
9. **Commit the changes**:
   ```bash
   git add -A
   git commit -m "docs(agents): update AGENTS.md for [change description]"
   ```

## Reference

See the full Mandatory Synchronization Rule in:
- `/AGENTS.md` → AGENTS.md Governance → Mandatory Synchronization Rule
