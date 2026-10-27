---
name: debug-session
description: Find and document problems in a codebase with parallel read-only subagents matched to each job, and sort every finding into broken (it fails), logic issue (it runs but is wrong) or coverage gap (nothing would catch it). Uses tests with coverage, static analysis, Playwright e2e, deep Opus bug hunts and a test audit. Produces FINDINGS.md and REPORT.md; fixes nothing. Use when asked to debug, audit, review or find bugs in a repo.
---

# Debug session (find and document)

Output: a ranked, evidence-backed `FINDINGS.md` and a `REPORT.md` in the repo root. **Nothing else in the repo changes**: no fixes, no new tests, no config edits.

You orchestrate and judge; subagents read and run. Narrate what you dispatch and why. Never record a finding without checking its evidence yourself. If `codebase-tour` was run first, reuse its map instead of re-running recon.

## Three kinds of finding

| Kind | Means | Typical examples | Evidence needed |
|---|---|---|---|
| **Broken** | It doesn't work | Crash, exception, failing test, 500 error, type or build error, broken UI flow, vulnerable dependency | The command and the error output |
| **Logic issue** | It runs, but the result is wrong or it allows the wrong thing | Wrong calculation, off-by-one, wrong status code, missing validation or permission check, race condition, timezone error | The triggering input, expected vs actual, and why the expected is right (spec, docs, naming, callers) |
| **Coverage gap** | Nothing would catch it if it broke | Untested logic, tests with weak assertions, missing edge cases, flaky tests, surviving mutants | Coverage lines, the weak assertion, or the mutant |

Broken findings are found by running things. Logic issues need reasoning about intent, so they get the strongest model. Coverage gaps aren't bugs yet; they show where the next bug will slip through.

## Agents and models

| Agent | Model | Finds mostly |
|---|---|---|
| `recon` | Haiku | Context: architecture, run/test commands, risky areas |
| `test-runner` | Sonnet | Broken (failing tests) and coverage numbers |
| `static-scanner` | Sonnet | Broken (type, build, dependency) and logic candidates |
| `e2e-tester` | Sonnet | Broken flows and visible logic issues, via Playwright MCP |
| `bug-hunter` | Opus | Logic issues, one risky area per agent |
| `test-auditor` | Sonnet | Coverage gaps, one area per agent |

## Scale to the repo
Count source lines first (exclude lockfiles, generated, vendored and config files) and say the plan out loud. Agents earn their place on code you can't read yourself in the time.

| Size | Source lines | Wide sweep | Deep dive |
|---|---|---|---|
| Small | under 1,500 | Read it yourself. Run tests with coverage and the linters yourself. `e2e-tester` only if there's a UI. | 1 `bug-hunter` on the riskiest file, if any. `test-auditor` only if there are tests worth auditing. |
| Medium | 1,500 – 15,000 | `test-runner` + `static-scanner`; `recon` only if no tour was done; `e2e-tester` if there's a UI | 2 `bug-hunter`, 1 `test-auditor` |
| Large | over 15,000 | All four in parallel | 3 `bug-hunter`, 1–2 `test-auditor` |

Keep `FINDINGS.md` proportional: a small repo has a handful of real findings, not a table per agent. Leave out empty sections.

## 1. Orient (~5 min)
- Ask the user: known symptoms or bug reports? What matters most? How is the app run?
- Read the README yourself. Start the app in the background if there's a UI or an API to call.

## 2. Wide sweep, in parallel (~10 min)
Launch at once, in the background: `recon`, `test-runner`, `static-scanner`, and `e2e-tester` if the app is running. Give `e2e-tester` a screenshot folder outside the repo (`<scratchpad>/evidence/`) for UI evidence.
While they work, use the app by hand and note anything odd.

## 3. Pick the deep-dive areas (~3 min)
Choose the 2-3 areas most likely to hide serious problems, from: recon's risky areas, the least-covered logic, failing tests, scanner hits. Favour code that moves money or quantities, enforces permissions, handles dates, or runs concurrently.

## 4. Deep dive, in parallel
- One `bug-hunter` (Opus) per area, at most 3 at once.
- One `test-auditor` (Sonnet) on the most critical area, with the coverage output from `test-runner`. Ask for mutation testing only if there's time.
- Meanwhile, verify wide-sweep findings: open the code at each file:line, and reproduce where it's cheap (run the failing test alone, call the endpoint, a one-liner). Drop anything you can't support. Recheck each finding's kind: a failing test can be broken *or* a logic issue.

## 5. Document
Copy `templates/FINDINGS.md` to the repo root. One row per distinct finding, de-duplicated across agents, in the right section, ranked within each section:
- **Critical:** data loss or corruption, wrong money or quantities, security holes, crashes on a main flow
- **High:** wrong results in a main flow; wrong status codes a client depends on
- **Medium:** edge cases, error handling, performance
- **Low:** UX and cosmetic

Give every row a confidence: confirmed by running, confirmed by reading, or suspected.

## 6. Report (~5 min, always leave time)
Fill `templates/REPORT.md` as `REPORT.md`: counts by kind and severity, the top findings, test health, what was checked and found clean, and next steps in priority order. A Haiku subagent can draft it from `FINDINGS.md`; you check it.

Reference: `references/bug-patterns.md` lists where subtle bugs hide.
