---
name: debug-session
description: Run a structured, multi-agent debugging session on an unfamiliar codebase - parallel recon, test-with-coverage and static-scan subagents, a ranked BUGS.md ledger, parallel fixes in worktrees, Playwright e2e, mutation testing, and a final report. Use when asked to debug, audit, or find and fix bugs in a repo, especially one you haven't seen before.
---

# Debug session

You orchestrate; subagents do the legwork; the main thread (you, on the strongest model) takes the hardest bug. Narrate what you dispatch and why. Never accept a subagent's claim without checking it (read the diff, rerun the test).

## 1. Orient (main thread, ~5 min)
- Ask the user for: known symptoms or bug reports, what counts as most important, whether existing tests may be changed, how the app is run.
- Read the README yourself. Note the run and test commands.

## 2. Recon in parallel (~10 min)
Launch these three **at once, in the background**, each with a one-paragraph brief that names the repo path and what to return:
- `recon` (Haiku): architecture map, run/test commands, risky areas.
- `test-runner` (Sonnet): suite running with coverage; failures and least-covered logic.
- `static-scanner` (Sonnet): lint, types, audit, classic bug patterns.

While they run, start the app and use it by hand (or ask the user to). Note anything odd.

## 3. Triage (~3 min)
Copy `templates/BUGS.md` to the repo root as `BUGS.md`. Merge all findings into it: one row per distinct bug, de-duplicated, with evidence. Rank:
1. **Critical:** crashes, data loss or corruption, wrong money or quantities, security holes.
2. **High:** wrong results in a main flow, wrong status codes an API client depends on.
3. **Medium:** edge cases, error handling, performance.
4. **Low:** UX and cosmetic.

Mark each bug **hard** (unclear cause, cross-cutting) or **easy** (clear cause, local fix).

## 4. Fix loop (bulk of the time)
- **Main thread:** take the top hard bug. Reproduce with a failing test, find the root cause (read code, add logging, use `git bisect run <test cmd>` if it used to work), fix, verify.
- **In parallel:** dispatch `fixer` (Sonnet) for each easy bug, **one bug per agent, each in its own worktree** (Agent tool `isolation: "worktree"`), at most 2 at a time. Review each returned diff and test before merging.
- **If there's a UI:** dispatch `e2e-tester` (Sonnet) to walk the main flows with Playwright MCP and turn problems into Playwright specs.
- Update `BUGS.md` status as each bug moves: open → reproduced → fixed (commit) → verified.
- Every fix has a regression test that failed before the fix.

## 5. Prove the tests (~7 min)
- Rerun coverage; record before/after in `BUGS.md`.
- Mutation testing on the one core module you changed most (it's slow, so keep the scope tight):
  - Python: `uv run mutmut run --paths-to-mutate <module>` then `mutmut results`
  - JS/TS: `npx stryker run --mutate "<file>"` (init with `npx stryker init` if needed)
  - Surviving mutants = assertions that would miss a real bug. Kill the important ones with a sharper test, or explain why not.

## 6. Report (~5 min, always leave time)
Fill `templates/REPORT.md` as `REPORT.md` in the repo root (a `haiku` subagent can draft it from `BUGS.md` and `git log`; you check it). Cover: summary, bugs fixed with root cause and test, bugs found but not fixed and why, coverage before/after, mutation score, risks and next steps.

## Model choice
- Haiku 5.5: reading, mapping, summarizing, drafting the report.
- Sonnet 5.5: running tests, scanning, well-scoped fixes, e2e.
- Opus 5.5 (main thread): triage judgment and the hard root causes.

Reference: `references/bug-patterns.md` for where subtle bugs hide.
