# task-083 — Dashboard: Emergency Model Control Page (Standalone)

## Objective
Provide a standalone emergency model control surface that remains available even if the main dashboard fails, letting Ronald inspect and change model assignments during outages or incidents.

## Scope
- Standalone service independent of dashboard runtime
- Full model switching for relevant agents
- Fallback chain visibility/editing
- Backend control path for reading/writing model config and restarting gateway
- Mobile-usable dark UI suitable for Ronald’s phone

## Acceptance Criteria
- [ ] Standalone service runs independently of the dashboard
- [ ] Ronald can load the page from the intended network path
- [ ] Current model and fallback state are visible clearly
- [ ] Control actions work through the expected config/restart flow
- [ ] The emergency surface remains available even if dashboard app is down

## Constraints / Requirements
- Independence from dashboard is mandatory
- UX should be operational and trustworthy under stress
- Mobile responsiveness matters
- This is emergency infrastructure, not decorative UI

## Context / Handoff
This task was revised from an in-dashboard page into a standalone project because the whole point is emergency access when other systems are broken. The separate project and launch path are now part of the required design, not an implementation detail.

## Verification
Confirm the standalone service boots, loads, exposes the intended model-control functionality, and remains separate from the dashboard runtime.
