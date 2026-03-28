# task-078 — Phase 3: Local model benchmark for crons/heartbeats/tasks — find best local replacements

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
Full benchmark complete. qwen3:8b wins (23/25, 9.8s avg). gemma3:4b best for fast classification (20/25, 1.6s). Recommend dropping qwen3.5:9b and nemotron-3-nano. Report at local-model-benchmark-2026-03-26.md

## Verification
Benchmark results document exists with scores for 5+ local models across heartbeat/cron/task scenarios; recommendation implemented
