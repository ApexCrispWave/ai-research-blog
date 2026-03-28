# task-016 — Create cross-channel chat history search rule — fallback when memory fails

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
Memory miss protocol added to AGENTS.md. When memory search fails: (1) grep chatlogs/ across all dates, (2) grep memory/ files, (3) use local model for semantic scan if needed, (4) pass results to relevant agent. Rule: search before shrug. Prevents repeat of PDF report miss.

## Verification
AGENTS.md or operating rules include chat history search protocol; uses local model to search chatlogs/; passes results to relevant agent; tested with a real query
