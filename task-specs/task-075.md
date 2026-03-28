# task-075 — BookForge AI — Fix 6 issues from Ronald feedback

## Objective
Legacy task migrated without a full objective yet.

## Scope
- Legacy task; scope needs cleanup if this task is reactivated

## Acceptance Criteria
- [ ] Spec needs explicit completion criteria

## Constraints / Requirements
- Preserve historical task context

## Context / Handoff
All 6 issues fixed by FORGE: 1) Add/remove pages with proper renumbering, 2) Gemini+OpenAI image providers visible in sidebar, 3) Aspect ratios respect book type (portrait for coloring/journal, square for children), 4) Model selector with 6 options (Anthropic/OpenAI/Local Ollama), 5) Coloring book template fixed (was hardcoded 1:1, now dynamic), 6) Exports page verified working (66 PDFs). Zero build errors.

## Verification
curl -s http://localhost:3002/ | grep -q BookForge && echo OK
