# task-001 — Infrastructure upgrade: local LLMs, memory system, multi-agent architecture, cost optimization

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
Installed Ollama, pulled qwen3:8b, gemma3:4b, nomic-embed-text. Updated openclaw.json with full config. Gateway restarted successfully.

## Verification
ollama list shows 3 models; openclaw gateway status shows running; cron list shows nightly-extraction
