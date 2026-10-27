---
name: codebase-tour
description: Get up to speed on an unfamiliar codebase fast. Parallel read-only agents map the stack, structure, data model and main flows, and a Playwright agent screenshots the running app; the result is published as an artifact page with screenshots, an architecture diagram, annotated folder map, data model, traced request flows, run and test commands, and where to change what. Use when asked to understand, explain, onboard onto, or map a repo.
---

# Codebase tour

Goal: one page someone can read in five minutes and then find their way around the repo. Read-only: nothing in the repo is changed.

## 1. Look yourself first (~3 min)
Before dispatching anything, skim by hand and say what you see: the README, the top-level folders (`ls`, `git ls-files | head -50`), the package manifests, `git log --oneline -15`. This gives you a picture to check the agents' summaries against.

If the README says how to run the app, start it now in the background (a free port, a throwaway database if the app takes one) so the screenshot agent has something to look at.

## 2. Map in parallel (~5 min)
Launch these **at once, in the background**, each with its own brief and the repo path.

**Screens (`e2e-tester`, Sonnet), if the app is running:** "Tour mode, not bug hunting. Visit the main screens with Playwright MCP and screenshot each one (full page, 1280 wide) into `<scratchpad>/tour/screens/NN-name.png`. For each, return the file name, the URL, one line on what a user does there, and the route or component that renders it if you can tell." For an API-only app, screenshot the API docs page (e.g. `/docs`) and one or two example responses instead.

**Four `recon` agents (Haiku):**
1. **Stack and layout:** languages, frameworks, versions, every top-level folder and its purpose, entry points, config and env vars.
2. **Data model:** every entity or table, its key fields and relationships, where it's defined, migrations.
3. **Main flows:** pick the 2-3 most important requests or user journeys and trace each one from entry point to database and back, as numbered steps with file:line.
4. **Run and test:** exact commands to install, run, test and lint; the test layout and frameworks; CI config. Try the commands and say which work.

Ask each for bullets with file paths, under 50 lines, and "not found" instead of guesses.

## 3. Verify (~3 min)
Open at least two cited files per agent and check the claims. Fix or drop anything wrong, and mention one correction out loud: it shows you're checking the AI, not repeating it.

## 4. Build the page
1. Call the Artifact tool's `quickstart` (intent `other`) once before writing.
2. Copy `templates/tour.html` to `<scratchpad>/tour/index.html` and fill every section. Replace every placeholder; delete a section only if it truly doesn't apply (no Screens section if nothing could be screenshotted).
3. Keep it short and specific: real file paths, real names, real commands. No filler.
4. The architecture diagram is a Mermaid flowchart (`<pre class="mermaid">`): boxes for the real modules, arrows for the real calls.
5. Look at each screenshot before using it; drop blank, error or login-wall shots.
6. Publish with the Artifact tool (icon `map`): `file_path` is the index.html, and pass each screenshot in `files` as `{"screens/NN-name.png": "<scratchpad>/tour/screens/NN-name.png"}` so the relative `<img src="screens/...">` paths resolve. Give the user the link.
7. Stop the app if you started it.

Sections: At a glance · Run it · Architecture · Screens · Folder map · Data model · Main flows · Where to change what · Risky areas and open questions · Glossary.
