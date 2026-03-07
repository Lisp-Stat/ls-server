# RALPH — Red Analyze Loop Plan Hypothesize

RALPH is an automated, iterative test-driven development system built on
[GitHub Copilot](https://github.com/features/copilot) custom agents and prompts.
It drives a product backlog (`prd.json`) to completion by cycling through:
run tests → analyze failures → plan a fix → implement → review → commit.

RALPH works identically in **VS Code Agent Mode** and the **Copilot CLI**,
enabling a hybrid workflow where long-running orchestration runs headless in a
terminal/tmux while interactive editing happens in the IDE.


## Prerequisites

| Requirement | Minimum version | Notes |
|---|---|---|
| [GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli) | v0.0.418+ | `copilot --version` to check |
| [VS Code](https://code.visualstudio.com/) | 1.106+ | With GitHub Copilot extension |
| [jq](https://jqlang.github.io/jq/) | 1.6+ | Used by lifecycle hooks |
| Project-specific runtime | varies | e.g., SBCL for Common Lisp projects |

## Browser/E2E Testing with Playwright

Playwright is used for automated browser and end-to-end (E2E) testing. All browser tests must pass for a reviewer PASS.

**How to run Playwright tests:**
```sh
npx playwright test
```
Place Playwright test scripts in `ls-server/tests/e2e/` or a similar directory.

## Quick Start

### CLI (headless / terminal)

```sh
# Default: claude-sonnet-4.6, 50 continues
copilot --autopilot --yolo \
  --agent ralph \
  --model claude-sonnet-4.6 \
  --max-autopilot-continues 50 \
  --add-dir .

# Override model via flag
copilot --autopilot --yolo \
  --agent ralph \
  --model claude-opus-4.6 \
  --max-autopilot-continues 30 \
  --add-dir .

# Override model via environment variable
COPILOT_MODEL=claude-opus-4.6 copilot --autopilot --yolo \
  --agent ralph \
  --model claude-opus-4.6 \
  --max-autopilot-continues 50 \
  --add-dir .
```

The `--add-dir .` flag grants the agent access to the project directory.
The `--yolo` flag auto-approves all tool calls (required for unattended operation).

### VS Code (Agent Mode)

| Action | How to invoke |
|---|---|
| **Start RALPH loop** | `@ralph` agent — or the `ralph-loop` prompt |
| **Resume after context reset** | `continue-work` prompt |
| **Run tests only** | `run-tests` prompt |
| **Write a single test** | `write-test` prompt |
| **End-of-session cleanup** | `@final-reviewer` agent |

## How It Works

### The Four Copilot CLI Modes

| Mode | Trigger | Use case |
|---|---|---|
| **Interactive** | Default | Ad-hoc questions, manual coding |
| **Plan** | `/plan` | Generate a step-by-step plan without executing |
| **Autopilot** | `--autopilot` | Autonomous multi-step execution |
| **Fleet** | `/fleet` | Parallel subagent execution |

**RALPH uses Autopilot mode.** The `--autopilot` flag lets the agent run
autonomously, iterating through the RALPH cycle without human confirmation at
each step. Combined with `--yolo` (auto-approve all tool calls), the
orchestrator runs fully hands-free.

### The RALPH Cycle

For each user story in `prd.json`:

```
┌─────────────────────────────────────────┐
│  1. RED — Run tests, capture output     │
│  2. ANALYZE — @analyst triages failures │
│  3. PLAN — Decide fix strategy          │
│  4. HYPOTHESIZE — @test-engineer fixes  │
│  5. REVIEW — @reviewer gates commit     │
│     ├─ PASS → commit, next story        │
│     └─ FAIL → back to step 4           │
│  6. LOOP — Repeat until green (max 10)  │
└─────────────────────────────────────────┘
```

**Reviewer gate**: The orchestrator does **not** commit until `@reviewer`
explicitly returns PASS. A FAIL sends reviewer feedback back to
`@test-engineer` for another fix iteration.

## Project Configuration

All project-specific configuration lives in **one place**:
`.github/copilot-instructions.md`. This file is automatically injected into
every Copilot interaction — agents never need to be told to read it.

The `<!-- BEGIN PROJECT-SPECIFIC -->` / `<!-- END PROJECT-SPECIFIC -->` block in
that file contains:

| Field | Purpose |
|---|---|
| Runtime | Implementation, build system, test framework |
| Key Conventions | Package patterns, naming, etc. |
| Test Constraints | Determinism, framework, float comparisons |
| Test Command | Full SBCL one-liner for `asdf:test-system` |
| Targeted Test Command | One-liner for isolating a single suite |
| Suite Hierarchy | `defsuite` tree for `write-test` prompt |
| Key Source Files | Files agents should read first |
| RALPH Invocation | CLI and VS Code entry points |
| Current Development Focus | What's being worked on right now |

This design means agent/prompt/skill files are **100% generic** — only
`copilot-instructions.md` changes between projects.

## prd.json Schema

The product backlog is a single JSON file at the project root:

```json
{
  "project": "my-project",
  "branchName": "feat/my-feature",
  "description": "Brief description of the work",
  "userStories": [
    {
      "id": "US-001",
      "title": "Short title",
      "description": "Detailed description of the work to be done",
      "acceptanceCriteria": [
        "First criterion",
        "Second criterion"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique identifier (e.g., `US-001`) |
| `title` | string | Short descriptive title |
| `description` | string | Detailed work description |
| `acceptanceCriteria` | string[] | Testable requirements |
| `priority` | number | Lower = higher priority; processed in order |
| `passes` | boolean | Set to `true` when story is complete |
| `notes` | string | Implementation notes added by the agent |

The orchestrator processes stories in `priority` order, skipping those with
`passes: true`.

## progress.json Schema

Accumulated learnings are stored as structured JSON entries:

```json
{
  "learnings": [
    {
      "id": 1,
      "category": "pattern",
      "text": "Description of the learning",
      "storyId": "US-001",
      "timestamp": "2026-03-04T12:00:00Z"
    }
  ]
}
```

| Field | Type | Values |
|---|---|---|
| `id` | number | Sequential integer |
| `category` | string | `"pattern"`, `"environment"`, `"pitfall"` |
| `text` | string | The learning content |
| `storyId` | string | Story that produced this learning |
| `timestamp` | string | ISO 8601 datetime |

Starts as `{"learnings": []}` and is append-only during the RALPH session.

## Agent Architecture

```
ralph (orchestrator)
├── analyst        — Analyzes test failures, reads source to find root cause
├── test-engineer  — Writes and fixes test code
├── reviewer       — Reviews changes for conventions and correctness
└── final-reviewer — End-of-session artifact cleanup and hygiene check
```

### Agent Files

All agents live in `.github/agents/`:

| File | Role | Model |
|---|---|---|
| `ralph.agent.md` | Orchestrator | Inherited from CLI `--model` flag |
| `analyst.agent.md` | Failure analysis (read-only) | `claude-sonnet-4.5` |
| `test-engineer.agent.md` | Code generation | Inherited from ralph |
| `reviewer.agent.md` | Code review (read-only) | `claude-sonnet-4.5` |
| `final-reviewer.agent.md` | Cleanup review (read-only) | `claude-sonnet-4.5` |

Read-only agents (analyst, reviewer, final-reviewer) use a smaller model since
they don't generate code. The test-engineer inherits the orchestrator's model
to ensure high-quality code generation.

> **Note**: The `model` and `handoffs` properties work in VS Code but are
> ignored on GitHub.com's coding agent (they degrade gracefully without error).

### Prompts

Prompts live in `.github/prompts/`:

| File | Purpose |
|---|---|
| `ralph-loop.prompt.md` | Full RALPH cycle instructions |
| `continue-work.prompt.md` | Resume after context window reset |
| `run-tests.prompt.md` | Run full or targeted test suite |
| `write-test.prompt.md` | Write a single test for a function |

### Skills

Skills live in `.github/skills/` and provide domain-specific reference
knowledge that Copilot loads when relevant:

| Directory | Content |
|---|---|
| `clunit2-testing/` | Test framework API reference (generic) |

Add project-specific skills here as the project grows. Skill files should
contain only generic reference material — project-specific usage patterns stay
in `copilot-instructions.md`.

## Lifecycle Hooks

Hooks live in `.github/hooks/` and run automatically at agent lifecycle events.

### prd.json Validation Hook

`ralph-guards.json` runs after every agent turn (`agentStop` event). It
validates both JSON syntax and required schema fields. If `prd.json` is invalid,
the hook blocks the agent and instructs it to fix the file before continuing.

The validation checks:
- JSON syntax (via `jq` parse)
- `.project` field present
- `.userStories` is an array
- Each story has `.id`, `.title`, `.description`, `.acceptanceCriteria` (array),
  `.passes` (boolean), and `.priority` (number)

### Available Hook Events

| Event | When it fires |
|---|---|
| `agentStop` | After every agent turn |
| `subagentStop` | After a sub-agent completes |
| `preToolUse` | Before a tool is called |
| `postToolUse` | After a tool completes |
| `sessionStart` | When a session begins |
| `sessionEnd` | When a session ends |

## Framework Immutability

The RALPH framework files in `.github/` are **immutable** during development:

```
.github/agents/          — never modified by RALPH
.github/prompts/         — never modified by RALPH
.github/hooks/           — never modified by RALPH
.github/skills/          — never modified by RALPH
.github/instructions/    — never modified by RALPH
```

The **only** file in `.github/` that RALPH may legitimately update is
`.github/copilot-instructions.md` (to record new project patterns or update the
current development focus).

The `@final-reviewer` agent verifies this at end-of-session.

## Adopting RALPH for Your Project

### Files to Copy

```
.github/
  agents/
    ralph.agent.md          — Orchestrator (generic)
    analyst.agent.md        — Failure analyst (generic)
    test-engineer.agent.md  — Test writer (generic)
    reviewer.agent.md       — Code reviewer (generic)
    final-reviewer.agent.md — Cleanup reviewer (generic)
  prompts/
    ralph-loop.prompt.md      — Main RALPH prompt (generic)
    continue-work.prompt.md   — Resume prompt (generic)
    run-tests.prompt.md       — Test runner prompt (generic)
    write-test.prompt.md      — Test writer prompt (generic)
  hooks/
    ralph-guards.json         — prd.json validation hook (generic)
  skills/
    clunit2-testing/SKILL.md  — clunit2 reference (generic)
  instructions/
    common-lisp.instructions.md — CL coding conventions (generic)
  copilot-instructions.md     — Project-level config (EDIT THIS)
prd.json                      — Your product backlog
progress.json                 — Accumulated learnings (starts as {"learnings": []})
```

### Customization — One File Only

The only file you need to edit is `.github/copilot-instructions.md`.
Fill in the `<!-- BEGIN PROJECT-SPECIFIC -->` / `<!-- END PROJECT-SPECIFIC -->`
section with:

1. **Runtime** — your CL implementation, build tool, test framework
2. **Key Conventions** — package patterns, naming, etc.
3. **Test Constraints** — determinism requirements, assertion helpers
4. **Reviewer Gate** — copy the standard gate text (already there as a template)
5. **Test Command** — your SBCL/ASDF one-liner
6. **Targeted Test Command** — one-liner for isolating suites
7. **Suite Hierarchy** — your `defsuite` tree
8. **Key Source Files** — files agents should read first
9. **RALPH Invocation** — CLI and VS Code entry points (template already there)
10. **Current Development Focus** — what you're working on now
11. **`prd.json`** — write your user stories
12. **`progress.json`** — starts empty; RALPH populates it automatically

## Troubleshooting

### Corrupted prd.json

**Symptom**: Agent reports "prd.json contains invalid JSON" or the `agentStop`
hook blocks.

**Fix**: Run `jq . prd.json` to see the parse error. Common causes:
- Trailing commas in arrays/objects
- Unescaped quotes in string values
- Incomplete edits from `multi_replace_string_in_file`

### Silent Test Output

**Symptom**: Tests run but produce no visible output.

**Fix**: When loading test systems with `:silent t`, clunit2's output stream
is suppressed. Rebind it:

```lisp
(let ((clunit:*test-output-stream* *standard-output*))
  (clunit:run-suite 'my-suite :report-progress t))
```

The project's `run-tests` function in `tests/main.lisp` should do this
automatically. See the clunit2 skill for details.

### Max Iterations Reached

**Symptom**: Agent stops after 10 iterations without resolving all failures.

**Fix**: This is a safety limit. Review `progress.json` for patterns, examine
the remaining failures manually, then restart with `continue-work` or re-run
the CLI command.

### Agent Not Found

**Symptom**: `copilot --agent ralph` fails with "agent not found".

**Fix**: Ensure `.github/agents/ralph.agent.md` exists and the frontmatter has
`name: ralph`. The `--add-dir` flag must point to the directory containing
`.github/`.

### Reviewer Loops Indefinitely

**Symptom**: The reviewer keeps returning FAIL on the same issue.

**Fix**: The orchestrator has a 10-iteration cap per story. If the reviewer's
feedback conflicts with the test framework or language conventions, update the
**reviewer agent's instructions** or the relevant **skill file** to clarify the
correct pattern. Do not edit the reviewer to be more lenient.

### model / handoffs Ignored on GitHub.com

**Symptom**: Sub-agents don't use the specified model; handoff buttons don't
appear when running the coding agent on GitHub.com.

**Fix**: This is expected. The `model` and `handoffs` frontmatter properties
are VS Code-only features and are silently ignored by GitHub.com's coding
agent. RALPH functions correctly either way — the handoffs are instructional in
the agent body, and the model selection is an optimisation, not a requirement.
