# task-011 — Design and implement local-only fallback mode (Limp Mode) for cloud API outages/rate limits

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
LIMP-MODE.md completed: JACK as primary fallback contact (#jack channel), activation triggers with manual phrases, heartbeat cloud health check added to HEARTBEAT.md, deferral protocol, decision matrix. Fallback chain already live in openclaw.json (Sonnet → qwen3.5:9b → qwen3:8b → gemma3:4b).

## Verification
Fallback config documented; openclaw.json has fallback model chain; tested with cloud models disabled; LIMP-MODE.md exists with operating procedures
