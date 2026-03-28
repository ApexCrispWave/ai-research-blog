# task-088 — Spec enforcement smoke test

## Objective
Validate that the new task system blocks under-specified work from moving into execution until a real handoff-quality spec exists.

## Scope
- Create a new low-priority task through task-manager.sh
- Confirm the auto-generated draft spec is created
- Confirm the task cannot move to in-progress while the draft spec remains incomplete
- Upgrade the spec to a handoff-ready state
- Confirm the task can then move to in-progress normally

## Acceptance Criteria
- [ ] Draft task is created with a companion markdown spec file
- [ ] Status transition to in-progress fails while the draft spec is incomplete
- [ ] Status transition succeeds after the spec is upgraded
- [ ] Queue/status views report the task as spec-ready after refresh

## Constraints / Requirements
- Use the live task manager scripts only
- Do not bypass enforcement with --force
- Keep this task as a contained smoke test for the new system

## Context / Handoff
This task exists solely to prove the enforcement model actually works in practice. The old system allowed thin tasks to drift into execution with almost no useful context. The new system should stop that. A new agent should be able to read this file and understand exactly what is being validated and what result counts as complete.

## Verification
Run task-manager add, attempt task-manager update to in-progress before and after spec completion, and check queue-manager status for spec readiness.
