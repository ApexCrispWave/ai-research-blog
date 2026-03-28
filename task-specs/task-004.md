# task-004 — Set up permanent daily chat log backups

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
Created export script, tested successfully (104 messages exported). Cron runs at 2:55 AM PT on gemma3:4b (free).

## Verification
chatlogs/2026-03-19.md exists with clean transcript; nightly-chatlog-export cron active
