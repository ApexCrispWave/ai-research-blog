# Task Specs — CrispWave Task System v3

## Why this exists
Thin tasks keep getting delegated badly. A title and one-line note are not enough for a new model, agent, or employee to pick up work cold.

Task specs are now first-class.

## Design
Each task now has two layers:

1. **`tasks.json` metadata**
   - fast board/status data
   - title, assignee, status, priority
   - short `description`
   - `spec` metadata:
     - `path`
     - `ready`
     - `completeness`
     - `wordCount`

2. **Companion markdown spec** in `task-specs/<task-id>.md`
   - durable editable task brief
   - objective
   - scope
   - acceptance criteria
   - constraints
   - context / handoff
   - verification

This split keeps the board fast while making the detailed spec unavoidable.

## Enforcement
A task is **not ready for delegation** unless its spec is complete.

Current readiness rules:
- spec file exists
- contains `## Acceptance Criteria`
- contains `## Context / Handoff`
- has at least ~80 words

If a task is not spec-ready:
- `queue-manager.py next` skips it
- queue status shows it as **spec-blocked**
- `task-manager.sh update <id> --status in-progress` fails
- `task-manager.sh update <id> --status done` fails

APEX or Ronald can override with `--force`, but the normal path is enforcement.

## Commands
### Add a task
```bash
bash scripts/task-manager.sh add \
  --title "Build pricing calculator" \
  --description "Interactive estimator for landing page" \
  --priority high \
  --assignee apex \
  --source ronald
```

This creates:
- a task in `tasks.json`
- a draft spec in `task-specs/task-XYZ.md`

### View a task
```bash
bash scripts/task-manager.sh show task-086
```

### Open/view the spec
```bash
bash scripts/task-manager.sh spec task-086
bash scripts/task-manager.sh spec task-086 --edit
```

### Replace/attach a spec from a prepared markdown file
```bash
bash scripts/task-manager.sh attach-spec task-086 --file /tmp/spec.md --actor apex
```

### Update short description
```bash
bash scripts/task-manager.sh set-description task-086 \
  --description "Operator cockpit overhaul" \
  --actor apex
```

### Refresh spec readiness metadata
```bash
bash scripts/task-manager.sh refresh-spec
bash scripts/task-manager.sh refresh-spec task-086
```

## Good vs weak spec

### Weak spec
> Build dashboard improvements.

Why it fails:
- no scope
- no acceptance criteria
- no handoff context
- impossible to verify

### Good spec
```md
# task-999 — Dashboard service visibility overhaul

## Objective
Make Ronald able to see all live services and reachable URLs at a glance.

## Scope
- Add running services panel
- Show Tailscale IP prominently
- Show Tailscale URLs for each service

## Acceptance Criteria
- [ ] Dashboard page shows all key services
- [ ] Tailscale IP is visible without scrolling
- [ ] Each service row shows local + Tailscale URL
- [ ] Page loads without errors

## Constraints / Requirements
- Keep UI operationally useful
- No clutter
- Preserve existing dashboard style

## Context / Handoff
Current dashboard already has service cards, but they are incomplete. Ronald prefers Tailscale URLs instead of localhost. This task is for the dashboard repo at /Users/openclaw/Projects/crispwave-dashboard.

## Verification
Open the dashboard, confirm service rows and Tailscale URLs render correctly.
```

## Migration
Legacy tasks are preserved. They can stay thin, but they will show `spec: missing` or `spec: draft` until upgraded.

Migration path:
1. create `task-specs/<id>.md`
2. run `bash scripts/task-manager.sh refresh-spec <id>`
3. task becomes ready once the spec satisfies readiness rules

## Ronald workflow change
Going forward:
- serious tasks need a real spec
- if you drop a task in quickly, the system will create a draft spec file
- delegation should happen only after the spec is upgraded to ready

That is intentional. The new goal is fewer ambiguous handoffs and less model thrash.
