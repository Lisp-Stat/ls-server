---
description: 'Resume RALPH development after devcontainer rebuild or context reset'
name: continue-work
agent: ralph
tools:
  - execute
  - edit
  - search
  - read
  - web
---

# Continue Development After Context Reset

This prompt resumes development work after a devcontainer rebuild or context reset.

## Steps

### 1. Check current state
- Read `.github/copilot-instructions.md` — reabsorb project context and test commands
- Read `prd.json` to see which user stories have `passes: true` vs `false`
- Read `progress.json` for accumulated learnings in the `learnings` array
- Verify which git branch is checked out
- Report: X of Y stories complete, next story is US-NNN

### 2. Verify test harness
Use the **Test Command** from `.github/copilot-instructions.md` to confirm the
test suite loads and runs cleanly.

### 3. Pick up next story
Find the highest-priority story in `prd.json` where `passes: false` and begin
implementation.

### 4. Follow RALPH loop
For each story:
1. Implement the change
2. Run tests (using the **Test Command** from `.github/copilot-instructions.md`)
3. If failures, analyze and fix (up to 10 iterations)
4. When green, delegate to `@reviewer` for CL convention check:
   - **PASS** → proceed to commit
   - **FAIL** → fix issues, re-test, re-review.
     **Do NOT commit until `@reviewer` returns PASS.**
5. When green **and** reviewer PASS:
   - Update `prd.json`: set `passes: true`, add notes
   - **Validate JSON**: run `jq empty prd.json` — fix any corruption before
     proceeding
   - Add new entry to `progress.json` `learnings` array with `id`, `category`,
     `text`, `storyId`, and `timestamp` (ISO 8601)
   - Commit: `feat(US-XXX): <story title>`
6. If capacity remains, immediately pick up the next `passes: false` story

### 5. Before stopping
Report:
- Stories completed this session
- Current test suite status
- Next story to pick up
