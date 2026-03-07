---
description: 'Run the test suite and report pass/fail results'
name: run-tests
tools:
  - execute
---

# Run Tests

Run the test suite and report the results.

## Full Suite

Use the **Test Command** from `.github/copilot-instructions.md`.

## Targeted Suite

To isolate failures without running the full suite, use the **Targeted Test
Command** from `.github/copilot-instructions.md`. Replace `SUITE-NAME` with the
suite or test name to isolate.

For a single test (instead of a whole suite), substitute:
```lisp
(clunit:run-test (quote test-name))
```
in place of `(clunit:run-suite ...)`.

## Parse Output

Look for clunit2 output lines containing:
- `PASS` / `FAIL` counts
- Individual test results
- Any compilation errors or warnings

## Report

1. Total tests run
2. Tests passed
3. Tests failed (with names and failure messages)
4. Any load/compilation errors
