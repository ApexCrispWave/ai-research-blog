# task-086 — Dashboard v2 Overhaul — Next-Generation Operator Cockpit

## Objective
Transform the CrispWave Dashboard into an executive operator cockpit that lets Ronald assess company/system state, blockers, active work, live services, and model/runtime health in one glance.

## Scope
- Add an executive brief section
- Surface blockers that specifically need Ronald
- Show active agents and Ralph-loop/restart activity
- Show live apps/services with reachable URLs
- Show critical alerts and recent operational events
- Show pipeline momentum and model/provider/runtime health
- Keep the presentation crisp, operational, and decision-oriented

## Acceptance Criteria
- [ ] Dashboard presents a clear top-level executive summary
- [ ] Ronald-facing blockers are visible and separated from general noise
- [ ] Live services and URLs are easy to scan and act on
- [ ] Active agent/runtime health is visible with meaningful status signals
- [ ] Critical alerts and recent operational events are surfaced clearly
- [ ] The page is more useful as an operator cockpit than the current dashboard

## Constraints / Requirements
- Prioritize operational clarity over visual novelty
- Ronald prefers Tailscale-accessible service URLs when sharing links
- Avoid clutter; sections should earn their place
- Reuse live data sources where possible

## Context / Handoff
This is the umbrella overhaul task beyond the point feature work in tasks 083–085. Ronald wants the dashboard to evolve from a collection of pages into a real control center. That means information hierarchy matters: what needs attention now, what is healthy, what is blocked, and what can be acted on immediately.

## Verification
Open the dashboard and confirm the major cockpit sections render correctly, live status data populates, and Ronald can quickly identify blockers, live services, and current system health.
