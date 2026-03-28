# task-077 — Phase 2: Reduce heartbeat token waste — optimize intervals and prompts

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
HEARTBEAT.md compressed 86% (19KB→2.7KB, 470→77 lines). Heartbeat already at 30min interval with GPT-5.4. All critical rules preserved. Full backup at HEARTBEAT-FULL-BACKUP.md.

## Verification
Heartbeat system prompt is <3000 tokens; heartbeat interval increased to 15+ min; token-per-heartbeat reduced by 50%+
