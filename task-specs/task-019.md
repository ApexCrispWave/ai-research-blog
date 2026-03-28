# task-019 — Switch default model to Sonnet — VECTOR becomes primary communicator, Opus only for escalation

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
Switched agents.defaults.model.primary and main agent to anthropic/claude-sonnet-4-6. Opus removed from all fallback chains. Local models (qwen3.5, qwen3, gemma3) are fallback. Gateway restarted and confirmed live. All conversations now Sonnet by default.

## Verification
openclaw.json default model is Sonnet; #general uses Sonnet/VECTOR; Opus only activates on explicit escalation; token usage drops significantly
