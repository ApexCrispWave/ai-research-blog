# task-046 — Fix heartbeat task board post to #task-board — must fire every 30 min

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
Fixed: created post-task-board.sh script that reads tasks.json and posts directly to Discord via API. Cron runs every 30 min on nemotron-3-nano:4b. Script confirmed working — posted successfully at 15:02 PT.

## Verification
Cron job exists and posts task board to Discord channel 1484408539974860871 every 30 min; confirmed delivery in channel
