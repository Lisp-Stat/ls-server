---
description: 'Execute the full RALPH loop — pick next story from prd.json, implement, test, commit'
name: ralph-loop
agent: ralph
tools:
  - execute
  - edit
  - search
  - read
  - web
---

# RALPH Loop

Execute the full RALPH (Red→Analyze→Loop→Plan→Hypothesize) cycle, driven by the
product backlog. Works identically in VS Code and Copilot CLI autopilot mode.

## Startup
1. Read `.github/copilot-instructions.md` — absorb project context, test commands,
   key files, suite hierarchy, and constraints.
2. Read `prd.json` — find all user stories where `passes` is `false`, sorted by
   `priority` ascending.
3. Read `progress.json` — absorb accumulated learnings from the `learnings` array.
4. Pick the **highest-priority** story that is not yet passing.

## Goal
Implement and verify the selected story. Iterate the RALPH cycle (up to 10
iterations) until its tests pass. Then mark the story as passing, commit, and —
if capacity remains in this turn — pick up the next story.

## Test Command
Use the **Test Command** from `.github/copilot-instructions.md`.

## Cycle (per story)
1. **Red** — Run the test command and capture output
2. **Analyze** — If failures, delegate to `@analyst` for root cause analysis
3. **Plan** — Based on analysis, determine what to fix (test expectation, test
   construction, or source code)
4. **Hypothesize** — Delegate fix to `@test-engineer`
5. **Review** — Delegate to `@reviewer` for CL convention check
   - **PASS** → Proceed to "On Green"
   - **FAIL** → Return to step 4 with reviewer feedback, re-fix, re-test,
     re-review. **Do NOT advance to On Green until `@reviewer` returns PASS.**
6. **Loop** — Re-run tests; repeat until green or 10 iterations

## On Green
When all tests pass for the current story **and `@reviewer` has returned PASS**:
1. Update `prd.json` — set `passes: true` for the completed story; add
   implementation notes.
2. **Validate JSON** — run `jq empty prd.json` to verify the file is valid JSON.
   If it fails, fix the corruption immediately.
3. Append new entry to `progress.json` `learnings` array — include `id`
   (next sequential integer), `category` (`"pattern"`, `"environment"`, or
   `"pitfall"`), `text` (the learning), `storyId` (e.g. `"US-001"`), and
   `timestamp` (ISO 8601).
4. Commit with message: `feat(US-XXX): <story title>`
5. Pick the next `passes: false` story and continue.

## Constraints
- Tests must be deterministic
- Use clunit2 framework
- Max 10 RALPH iterations per story
- Never modify files in `.github/agents/`, `.github/prompts/`, `.github/hooks/`,
  `.github/skills/`, or `.github/instructions/`

## Report
After completion (or when stopping), summarize:
- Stories completed this session (IDs and titles)
- Number of RALPH iterations per story
- Final pass/fail status of the full test suite
- Next story to pick up
- Any remaining issues
