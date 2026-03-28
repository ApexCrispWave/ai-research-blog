# task-033 — GitHub integration — manage PRs, issues, CI from APEX

## Objective
Enable CrispWave operators to manage GitHub issues, pull requests, and CI status directly through the local GitHub CLI workflow.

## Scope
- Use gh CLI for issue/PR/CI operations
- Verify auth is configured on the machine
- Unblock real GitHub actions from the agent environment
- Keep the blocker visible if Ronald action is still required

## Acceptance Criteria
- [ ] gh auth state is verified
- [ ] At least one real GitHub read action is possible when unblocked
- [ ] The blocker is explicit if auth is still missing
- [ ] Future operator knows exactly what Ronald must do

## Constraints / Requirements
- Do not fake GitHub readiness without auth
- Keep the blocker state honest and actionable

## Context / Handoff
This task is blocked because gh CLI auth requires Ronald to complete an interactive login flow. The important thing is not implementation complexity but making the blocker unmistakable and future follow-up trivial.

## Verification
Run gh auth status or equivalent and confirm whether authenticated GitHub operations are available.
