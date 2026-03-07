# Copilot Instructions for ls-server (Lisp-Stat)

## Project Overview
`ls-server` is an HTTP server for the [Lisp-Stat](https://lisp-stat.dev/) system,
based on the Hunchentoot HTTP server. It provides four functions:

1. **Plot viewing** — serve plots created with the `plot/vega` system
2. **Data frame viewing and editing** — view and edit data frames via HTTP
3. **CSV / JSON data serving** — serve data-frame contents in CSV and JSON format
4. **Vega-Lite spec serving** — serve Vega-Lite plot specifications for existing plots

### Subsystems
<!-- Populate as the project develops -->

<!-- BEGIN PROJECT-SPECIFIC -->

### Runtime
- **Common Lisp implementation**: SBCL (Steel Bank Common Lisp)
- **Build system**: ASDF
- **Test framework**: clunit2
- **HTTP server**: Hunchentoot

### Key Conventions
- Packages use `uiop:define-package` with explicit `:export` lists
<!-- Add project-specific conventions as they emerge -->

### Test Constraints
- Tests must be deterministic — no randomness, no timing dependencies
- Use clunit2 framework (not FiveAM or parachute)
- Use `num=` for floating-point comparisons with appropriate tolerance
- Test files are in `tests/` directory
- The test package `ls-server-tests` uses clunit2

### Reviewer Gate
- **No commit until `@reviewer` returns PASS.** After all tests pass (including Playwright browser tests), the `@reviewer`
  agent inspects the changes for CL conventions, clunit2 best practices, package hygiene, and browser test coverage.
- A FAIL verdict loops back to `@test-engineer` for fixes, then re-test, then re-review.
- This applies in both VS Code (`@ralph` agent) and CLI (`--agent ralph --autopilot`) modes.

### Test Command
```sh
cd /workspace && sbcl --non-interactive \
  --eval '(push #p"/workspace/" asdf:*central-registry*)' \
  --eval '(ql:quickload :ls-server :silent t)' \
  --eval '(ql:quickload :clunit2 :silent t)' \
  --eval '(asdf:test-system "ls-server")'
# Run Playwright browser tests (if present)
npx playwright test || exit 1
```
<!-- TODO: Adjust package name and system name once ASDF system is defined -->

### Targeted Test Command
To run a single suite without the full test run (rebind `*test-output-stream*` to see output):
```sh
cd /workspace && sbcl --non-interactive \
  --eval '(push #p"/workspace/" asdf:*central-registry*)' \
  --eval '(ql:quickload :ls-server :silent t)' \
  --eval '(ql:quickload :clunit2 :silent t)' \
  --eval '(let ((clunit:*test-output-stream* *standard-output*)) (clunit:run-suite (quote SUITE-NAME) :report-progress t))'
```
Replace `SUITE-NAME` with the suite to isolate.

### Suite Hierarchy
```lisp
;; TODO: populate as suites are created
(defsuite all-tests ())
```

### Key Source Files
<!-- TODO: populate as source files are created -->
- System definition: `ls-server.asd`
- Test package: `tests/test-package.lisp`
- Test runner: `tests/main.lisp`

### How to Run the RALPH Development Loop

This project uses the **RALPH** (Red→Analyze→Loop→Plan→Hypothesize) iterative
development cycle, driven by `prd.json` (product backlog) and `progress.json`
(accumulated learnings). See [README-RALPH.md](../README-RALPH.md) for full documentation.

**Two entry points** — both drive from the same `prd.json` and `progress.json`.
Do not run both simultaneously.

#### CLI (headless / terminal)
```sh
# Default: claude-sonnet-4.6, 50 continues
copilot --autopilot --yolo \
  --agent ralph \
  --model claude-sonnet-4.6 \
  --max-autopilot-continues 50 \
  --add-dir .

# Override model
COPILOT_MODEL=claude-opus-4.6 copilot --autopilot --yolo \
  --agent ralph \
  --model claude-opus-4.6 \
  --max-autopilot-continues 50 \
  --add-dir .
```

#### VS Code Copilot Chat (Agent Mode)

| Action | How to invoke |
|--------|---------------|
| **Start RALPH loop** | Use the `ralph-loop` prompt — or `@ralph` agent |
| **Resume after reset** | Use the `continue-work` prompt |
| **Run tests only** | Use the `run-tests` prompt |
| **Write a new test** | Use the `write-test` prompt |
| **End-of-session cleanup** | `@final-reviewer` agent |

### Playwright Integration

**Browser/E2E Testing:**
- Playwright is used for headless browser and end-to-end (E2E) testing.
- Tests should be placed in `ls-server/tests/e2e/` or similar.
- To run Playwright tests: `npx playwright test`
- Playwright tests are required to pass for a reviewer PASS.

### Current Development Focus
<!-- TODO: update as focus shifts -->
**Current state**: Fixing bugs, adding minor features, Playwright browser test integration.

<!-- END PROJECT-SPECIFIC -->
