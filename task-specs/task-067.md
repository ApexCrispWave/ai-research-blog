# task-067 — Get Privacy.com virtual card for APEX — domain purchase + recurring services

## Objective
Obtain a controlled payment method Ronald can authorize for approved recurring services and domain purchases.

## Scope
- Preserve why the card is needed
- Keep ownership clearly with Ronald where money/identity is involved
- Make unblock step explicit

## Acceptance Criteria
- [ ] The required human action is explicit
- [ ] Future operator knows what credential/artifact is needed
- [ ] Task remains blocked honestly until Ronald completes it

## Constraints / Requirements
- Money/identity actions stay with Ronald
- Do not attempt workaround paths that bypass that boundary

## Context / Handoff
This is blocked because creating and funding the card is Ronald territory. The task should remain visible because several downstream purchases depend on it.

## Verification
Confirm whether the payment artifact exists; if not, keep the blocker explicit.
