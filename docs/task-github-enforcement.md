# Task GitHub Enforcement

Coding/software tasks now require GitHub repo linkage before execution or delegation can start.

## New task fields

- `github_required`: whether a GitHub repo is mandatory before execution
- `repo_name`: `owner/repo` when known
- `repo_url`: GitHub URL when known
- `repo_status`: one of `linked`, `ready`, `active`, `missing`, `blocked`, `archived`, `planned`, `unknown`, `not-required`
- `execution_ready`: final gate used by task manager + queue manager
- `execution_block_reason`: human-readable reason when blocked

## Enforcement behavior

A task can only move to `in-progress` or `done` when:

1. `spec.ready == true`
2. if `github_required == true`, the task has `repo_name` or `repo_url`
3. if `github_required == true`, `repo_status` is `linked`, `ready`, or `active`

If repo linkage is missing, `task-manager.sh update ... --status in-progress` fails with a concrete fix command.

## Commands

Attach repo linkage:

```bash
scripts/task-manager.sh set-github task-090 \
  --actor apex \
  --required true \
  --repo-name owner/repo \
  --repo-url https://github.com/owner/repo \
  --repo-status linked
```

View repo linkage:

```bash
scripts/task-manager.sh github task-090
```

Clear repo linkage:

```bash
scripts/task-manager.sh clear-github task-090 --actor apex
```

Backfill metadata on existing tasks:

```bash
scripts/task-manager.sh migrate-github
```

## Migration path

- Existing tasks are heuristically marked `github_required: true` when they look like coding/software work.
- Historical done/cancelled tasks are annotated for visibility but not automatically reopened.
- Active/pending coding tasks without repo linkage will show `execution_ready: false` until linked.

## What Ronald must do differently

Before asking APEX/VECTOR/Codex/Claude Code to build or fix software:

1. create or choose the GitHub repo first
2. attach that repo to the task with `set-github`
3. only then start execution/delegation

Non-coding tasks continue to work without GitHub metadata.
