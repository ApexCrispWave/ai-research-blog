# task-085 — Dashboard: Quick-Switch Model Bar on Homepage

## Objective
Add a fast model switching strip to the main dashboard so Ronald can make common model changes instantly without drilling into the full control panel.

## Scope
- Add a prominent quick-switch bar to the dashboard home page
- Include HAIKU, SONNET, and OPUS primary switches for APEX/main control
- Show the currently active model clearly
- Optionally expose quick per-agent toggles in an expandable section
- Reuse the same backend model APIs as the broader control surfaces

## Acceptance Criteria
- [ ] Homepage shows a visible quick-switch bar without cluttering the layout
- [ ] Main quick actions change the intended model state through the existing API path
- [ ] Current active model is visually obvious
- [ ] Quick-switch interactions require reasonable confirmation/safety
- [ ] Homepage remains usable on desktop and mobile

## Constraints / Requirements
- Keep the homepage focused and fast
- Reuse model-control plumbing from task-083/084
- Optimize for Ronald’s most common actions, not edge-case configuration

## Context / Handoff
The full model panel is useful for deep control, but Ronald often just needs an immediate mode change. This task provides the shortcut layer. It is intentionally narrower than task-084 and should feel like an operator hotbar rather than a settings screen.

## Verification
Open the homepage, confirm the quick-switch bar renders, active model state is shown, and at least one quick-switch action updates through the expected backend path.
