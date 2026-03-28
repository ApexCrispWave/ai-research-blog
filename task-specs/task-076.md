# task-076 — Phase 1: Token Usage Dashboard — build tracking + dashboard page

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
Token dashboard live at localhost:3000/tokens. Tracks 14M tokens across 416 sessions, 13 models, 5 session types. Total spend: $57.78. API at /api/tokens. Token-tracker.js scans JSONL session files.

## Verification
curl -s http://localhost:3000/tokens returns HTML with token usage data; token-usage.json exists with per-model data
