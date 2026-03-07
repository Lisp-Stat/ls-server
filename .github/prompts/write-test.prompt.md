---
description: 'Write a new clunit2 test for a specified function or behavior'
name: write-test
agent: test-engineer
tools:
  - edit
  - search
  - read
---

Write a new clunit2 test for: ${input:target:Function or behavior to test}

## Process
1. **Read** `.github/copilot-instructions.md` for the suite hierarchy and key
   test files.
2. **Read** the source implementation of the target function.
3. **Understand** what it returns, its edge cases, and type behavior.
4. **Create** tests in the appropriate test file and suite.
5. Follow all Common Lisp and clunit2 conventions.

## Test Template
```lisp
(deftest descriptive-name (appropriate-suite)
  "Docstring describing the behavior under test."
  (let* (;; setup
         ;; exercise
         )
    (assert-equalp expected actual)))
```

## Constraints
- Tests must be deterministic — no randomness, no timing dependencies
- One behavior per test
- Every `deftest` **must** have a docstring
- All float literals must use the `d0` suffix (`1.0d0`, `0.5d0`) — never bare `1.0`
- Use `let*` for sequential bindings
- Place all helper `defun`s together near the top of the file
- Isolate uses of internal (`::`) symbols into named helper functions with a
  `NOTE` comment
- The test package uses `(:use :clunit)` — **never use the `clunit:` prefix** in
  test code

### CL Assertion Pitfalls

1. **Multi-value returning ops** — `round`, `truncate`, `floor`, `ceiling` return
   two values. Wrap the call in `(nth-value 0 ...)`:
   ```lisp
   ;; BAD — captures both values, comparison fails
   (assert-eql 3 (round 3.5d0))
   ;; GOOD
   (assert-eql 4 (nth-value 0 (round 3.5d0)))
   ```

2. **No multi-value in Expected position** — Never put a multi-value-returning
   form as the *expected* argument:
   ```lisp
   ;; BAD
   (assert-eql (floor 7 2) (floor 7 2))
   ;; GOOD
   (assert-eql 3 (nth-value 0 (floor 7 2)))
   ```

3. **Prefer `assert-equalp` for arrays** — Use a single `assert-equalp` with a
   literal expected array, not per-element assertions:
   ```lisp
   ;; BAD
   (assert-eql 1 (aref result 0))
   (assert-eql 2 (aref result 1))
   ;; GOOD
   (assert-equalp #(1 2) result)
   ```

4. **Test public API, not internals** — Test user-facing functions, not internal
   helpers.

## Numeric Comparisons
Use `num=` for floating-point assertions when `equalp` would be too strict:

```lisp
(assert-true (num= expected actual))       ; default tolerance
(assert-true (num= expected actual 1d-7))  ; explicit tolerance
```
