# task-028 — Sentry Pipeline — autonomous bug detection, triage, fix, and PR

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
Sentry pipeline built: error-monitor.sh, triage-error.py (12/12 tests), attempt-autofix.sh, LaunchAgent running every 5min. Architecture doc at security/SENTRY-PIPELINE.md. Auto-fix separate from auto-execution for safety.

## Verification
Sentry alert triggers APEX triage; auto-fixable bugs spawn Codex, open PR to staging; human gets notified; non-trivial bugs escalated
