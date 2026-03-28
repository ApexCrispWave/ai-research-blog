# task-021 — Local LLM stack detailed report — model inventory, purpose, permanence, recommendations

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
PDF uploaded to #status-updates Discord channel
