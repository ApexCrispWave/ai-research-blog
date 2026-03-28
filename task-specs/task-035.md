# task-035 — Calendar integration — read and create calendar events

## Objective
Enable calendar read/create operations for Ronald’s workflow once local permissions or tooling are available.

## Scope
- Determine viable calendar access path on this machine
- Use native automation or a CLI bridge
- Keep blocker explicit if permissions/tooling are missing

## Acceptance Criteria
- [ ] Read path for upcoming events is identified or implemented
- [ ] Create-event path is identified or implemented
- [ ] If blocked, the exact missing permission/tooling is stated clearly
- [ ] Future operator can resume without re-researching the blocker

## Constraints / Requirements
- Respect macOS permission boundaries
- Do not claim integration is live without successful reads

## Context / Handoff
The current blocker is around Calendar access permissions/tooling. This task should remain blocked until that prerequisite is resolved, but the spec should make the next step obvious.

## Verification
Attempt calendar access with the chosen method and confirm success or the exact blocking failure.
