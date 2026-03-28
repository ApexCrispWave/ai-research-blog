# task-084 — Dashboard: Full Model Control Panel Page

## Objective
Build a dedicated model management page inside the CrispWave Dashboard that gives Ronald a clean operational view of current model assignments, fallback chains, and provider health without needing to open raw config files.

## Scope
- Add a dashboard page for full model management
- Show agent cards with current model assignments and status
- Show fallback chain state clearly for each agent
- Surface provider health indicators if available
- Keep the page integrated with dashboard navigation and style

## Acceptance Criteria
- [ ] A dedicated model control page exists in the dashboard and loads without errors
- [ ] Each relevant agent shows current primary model and fallback state
- [ ] Model-switch actions are clearly presented and confirmed before apply
- [ ] The page is visually consistent with the rest of the dashboard
- [ ] Ronald can understand the current model state at a glance

## Constraints / Requirements
- Reuse existing emergency-control/API work where practical
- Keep the UI operational, not cluttered
- Prioritize safe visibility and usability over fancy visuals

## Context / Handoff
Task-083 created the standalone emergency control surface because model control had to survive dashboard failure. Task-084 is the dashboard-integrated counterpart: a normal operational control page for everyday use. It should not replace the standalone emergency app, but it should expose the same important information cleanly for regular operator workflows.

## Verification
Load the dashboard model page, confirm cards render, model state is visible, navigation works, and model actions call the intended APIs without breaking the dashboard.
