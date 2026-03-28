# task-020 — Delegate dashboard hosting to local agent — must stay up always, auto-recover

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
Dashboard rebuilt: Node.js server at port 3000, reads tasks.json live, auto-refreshes every 30s. LaunchAgent (com.crispwave.dashboard) for auto-start + KeepAlive. Accessible at http://100.98.64.77:3000 via Tailscale.

## Verification
Dashboard is up and accessible via Tailscale; cron health check running on local model; auto-restarts on failure; Ronald confirms it's accessible
