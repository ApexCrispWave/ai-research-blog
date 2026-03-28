# task-014 — Fix cron nightly jobs — gemma3:4b doesn't support tools

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
Root cause: gemma3:4b doesn't support tool calls. Chatlog-export and backup crons were on gemma3:4b, failed instantly. Switched both to qwen3:8b. Ran manually — chatlog (457 msgs) and backup (1.3M) completed. Tonight's runs should work.

## Verification
openclaw cron list shows all nightly crons on qwen3:8b; manual runs succeed
