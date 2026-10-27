# Debugging report: <repo>

## Summary
<Two or three sentences: how many bugs found, how many fixed, the most serious one, and the state of the test suite now.>

## Fixed

| # | Bug | Severity | Root cause | Fix | Regression test | Commit |
|---|---|---|---|---|---|---|
| | | | | | | |

## Found, not fixed

| # | Bug | Severity | Why not fixed | Suggested fix |
|---|---|---|---|---|
| | | | | |

## Test suite
- Tests: <before> → <after> (passing / total)
- Coverage: lines <before>% → <after>%, branches <before>% → <after>%
- Mutation score on <module>: <before>% → <after>%
- New tests added: <unit / integration / e2e counts>

## How this was done
- Agents: recon (Haiku), test-runner and static-scanner (Sonnet) in parallel; fixers in separate worktrees; e2e with Playwright.
- Every fix was verified by a test that failed before the fix.

## Risks and next steps
-
