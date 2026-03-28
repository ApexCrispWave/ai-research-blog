# task-045 — Fix underlying cause of edit tool failures on workspace files

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
Root cause: edit tool requires exact character match, fails on any whitespace diff. Fix: enforced rule in AGENTS.md to always use exec+python3 for file edits on workspace files. Edit tool now explicitly discouraged for .md files and tasks.json.

## Verification
AGENTS.md has enforced rule to use exec+python3 for file edits; no more edit tool failures on workspace files
