---
name: codebase-tour
description: Get up to speed on an unfamiliar codebase fast and publish a short artifact page explaining it - what it does, how to run it, an architecture diagram, screenshots of the running app, and where to change what. Effort and page length scale with the size of the repo. Use when asked to understand, explain, onboard onto, or map a repo.
---

# Codebase tour

Goal: a page someone reads in **2 minutes** (small repo) to **5 minutes** (large repo) and can then find their way around. Read-only: nothing in the repo changes.

**The page must be much shorter than the code it explains.** If a reader could get the same thing faster by opening the file, cut it.

## 1. Size it first (1 min)
Count source lines, excluding lockfiles, generated code, vendored and config files:
```
git ls-files | grep -vE 'lock|\.json$|\.md$|\.ya?ml$|\.toml$|dist/|vendor/' | xargs wc -l 2>/dev/null | tail -1
```
| Size | Source lines | Who reads it | Page budget |
|---|---|---|---|
| Small | under 1,500 | You, directly. No recon agents. | ~400 words |
| Medium | 1,500 – 15,000 | 2 `recon` agents (Haiku): structure + flows | ~900 words |
| Large | over 15,000 | 4 `recon` agents (Haiku): stack/layout, data model, flows, run/test | ~1,500 words |

Say the size and the plan out loud: "It's 180 lines, so I'll just read it; agents would cost more time than they save."

## 2. Read
- Always: skim the README, top-level folders, manifests and `git log --oneline -10` yourself first.
- Small: read the source files yourself.
- Medium and large: dispatch the recon agents in parallel, in the background, each with a narrow brief and a 40-line limit. While they run, keep reading. Then open two cited files per agent to check their claims, and mention one correction if you find one.

## 3. Screenshots (only if there's a UI or an API docs page)
Start the app in the background (free port, throwaway database). Dispatch one `e2e-tester` (Sonnet) in tour mode: "Screenshot the main screens with Playwright MCP into `<scratchpad>/tour/screens/NN-name.png`, 1280 wide; return file, URL and one line each." Use at most 3 screenshots for a small app, 6 for a large one. Look at each and drop blank or error shots. Stop the app afterwards.

## 4. Write the page
1. Call the Artifact tool's `quickstart` (intent `other`) once.
2. Copy `templates/tour.html` to `<scratchpad>/tour/index.html` and fill it within the word budget.
3. **Always include:** At a glance, Run it, Architecture (Mermaid flowchart of the real modules), Where to change what.
4. **Include only when it adds something:**
   - Screens: if there's anything to see.
   - Folder map: medium and large only, folders plus the few key files, never every file.
   - Data model: only with 3 or more entities.
   - Main flows: up to 3, at most 5 steps each, file names only; line numbers only where they matter.
   - Watch out: at most 3 items, about the code (not repo housekeeping like uncommitted files).
   - Open questions: at most 3, and only questions the team could answer.
   - Glossary: only for domain terms a newcomer wouldn't know, never tool names.
5. Read the finished page against the budget and cut before publishing.
6. Publish with the Artifact tool (icon `map`). `file_path` is the index.html; pass screenshots in `files` as `{"screens/NN-name.png": "<scratchpad>/tour/screens/NN-name.png"}`. Give the user the link.

This skill explains; it doesn't hunt bugs. Leave findings to `debug-session`; mention a risk only if a newcomer would trip over it.
