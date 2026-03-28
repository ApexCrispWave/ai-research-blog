# task-082 — Dashboard: Hybrid Pixel Office + Live Data Panel

## Objective
Build the hybrid dashboard page that combines a visual office scene with a truly useful live operational data panel for Ronald.

## Scope
- Left side visual office scene
- Right side live data panel for agents, metrics, recent completions, and cost state
- Polling/live refresh behavior
- Mobile-responsive layout
- Graceful handling of missing or partial backend data

## Acceptance Criteria
- [ ] Hybrid page exists and loads successfully
- [ ] Visual office renders on the left
- [ ] Data panel shows live or graceful-fallback operational data on the right
- [ ] Page updates on the intended cadence without crashing
- [ ] Layout remains readable on phone-sized screens

## Constraints / Requirements
- Must be operationally useful, not just pretty
- Gracefully degrade if some APIs are missing
- Reuse existing dashboard data plumbing where possible

## Context / Handoff
This task is important because it combines the visual dashboard experiments with real operator value. A prior delegated pass failed before delivery, so the task remains open. The intended bar is a page Ronald can actually use for real-time monitoring, not just admire.

## Verification
Open the page, verify rendering, confirm polling behavior, and check that agent/task/cost sections populate or fall back cleanly.
