# Findings report: <repo>

## Summary
<Two or three sentences: what was found, the most serious problem, and how much the tests can be trusted.>

| | Critical | High | Medium | Low | Total |
|---|---|---|---|---|---|
| Broken | | | | | |
| Logic issues | | | | | |
| Coverage gaps | | | | | |

## Top findings

| # | Kind | Finding | Severity | Impact | Evidence | Suggested fix |
|---|---|---|---|---|---|---|
| | | | | | | |

Full list with triggers and evidence: `FINDINGS.md`.

## Test health
- Suite: <passed> / <total>; <failing> failing, <flaky> flaky
- Coverage: <lines>% lines, <branches>% branches
- Biggest gaps: <untested logic that matters>
- Mutation score on <module>: <score> (if run)

## What was checked
- Wide sweep: recon (Haiku); test-runner, static-scanner, e2e-tester (Sonnet), in parallel.
- Deep dives: bug-hunter (Opus) on <areas>; test-auditor (Sonnet) on <area>.
- Found clean: <areas>
- Not covered: <what wasn't looked at, and why>

## Recommended next steps
1. <Highest-impact fix first>
2.
3.
