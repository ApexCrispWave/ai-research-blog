# task-044 — Register domain via browser automation (Porkbun)

## Objective
Complete the domain registration workflow through Porkbun once Ronald authorizes/provides the payment step.

## Scope
- Preserve the researched domain and pricing context
- Keep the workflow resumable from the point of payment
- Make the human-required blocker explicit

## Acceptance Criteria
- [ ] Chosen domain and registrar context are preserved
- [ ] Purchase blocker is clearly identified as Ronald/payment controlled
- [ ] Future resumption does not require redoing the full setup research

## Constraints / Requirements
- Do not attempt payment without Ronald
- Treat checkout/payment as human approval territory

## Context / Handoff
Research and checkout prep were already done, but the final purchase step requires Ronald’s intervention. This spec exists so the task stays actionable rather than vaguely blocked.

## Verification
Confirm the intended domain and checkout state are documented and that the task notes still match reality.
