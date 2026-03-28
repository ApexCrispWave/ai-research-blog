# task-032 — ChatCompletions API endpoint — expose OpenClaw as OpenAI-compatible API

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
ChatCompletions endpoint enabled in gateway.http.endpoints.chatCompletions.

## Verification
OpenClaw gateway exposes /v1/chat/completions; any OpenAI-compatible tool can hit APEX with full memory + tools + identity
