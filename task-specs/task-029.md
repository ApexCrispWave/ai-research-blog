# task-029 — Ralph Loop — auto-restart stalled coding agents

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
ralph-loop.sh created at workspace/scripts/ralph-loop.sh. Auto-restarts coding agents on timeout/crash, up to max_iterations. Fires wake event on completion. Documented in AGENTS.md.

## Verification
Coding sub-agents auto-restart when stalled or timed out; PRD checklist used to verify completion; no manual intervention needed for routine failures
