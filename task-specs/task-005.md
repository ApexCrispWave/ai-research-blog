# task-005 — Set up daily backup system with restore capability

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
Created backup script (workspace, config, cron, sessions, ollama manifest), restore script, first backup taken (602K). Auto-prunes after 30 days. Cron at 3:10 AM PT on gemma3:4b.

## Verification
~/backups/apex/apex-backup-2026-03-19_1946.tar.gz exists; nightly-backup cron active; restore script exists
