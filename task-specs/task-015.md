# task-015 — Add heartbeat check for unanswered messages across ALL Discord channels

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
HEARTBEAT.md updated with full Discord channel scan procedure. Checks #general, #ops, #task-board, #jack every heartbeat. Creates tasks for unanswered messages. Tracks state in memory/heartbeat-state.json.

## Verification
HEARTBEAT.md includes Discord channel scan step; heartbeat checks #general, #ops, #task-board for unanswered Ronald messages; creates tasks for anything missed
