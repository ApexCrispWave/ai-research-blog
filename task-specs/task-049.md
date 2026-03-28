# task-049 — Set up free practice email for APEX

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
Email apexcrispwave@sharebot.net created via mail.tm API. Credentials saved to memory/apex-email.json.

## Verification
curl -s -X POST https://api.mail.tm/token -H "Content-Type: application/json" -d "{"address":"apexcrispwave@sharebot.net","password":"CrispWave@Apex2026!"}" | python3 -c "import json,sys; print(json.load(sys.stdin).get("token","")[:10])"
