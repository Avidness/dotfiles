---
name: scaffold-app
description: Create a new app project from scratch under ~/projects - FastAPI backend, plus an optional React frontend, Postgres, and Claude tool-use agent loop - with lint, type checks, tests, git hooks and CI passing from the first commit. Use when the user asks to start, create, bootstrap or scaffold a new app, API, service or agent project.
---

# Scaffold a new app

1. Choose flags from the request. Ask only if it's unclear whether a UI is wanted.
   - `--agent`: Claude tool-use agent loop with a scripted fake model for tests. Use for any agent or LLM app.
   - `--web`: Vite + React + TypeScript frontend. Only when a UI is asked for.
   - `--postgres`: Postgres via docker compose. Without it, use SQLite or in-memory storage behind a small repository class.
2. Run the script with a kebab-case name:
   ```
   ~/.claude/skills/scaffold-app/scaffold.sh <name> [--agent] [--web] [--postgres]
   ```
   It creates `~/projects/<name>`, installs dependencies, runs `just check`, installs git hooks and makes the first commit. Use `--dir <parent>` for a different parent folder.
3. Read the generated `CLAUDE.md`. Add the project's domain rules (invariants, states, limits) to its Rules section as soon as they're known.
4. Tell the user what was created and the main commands: `just dev`, `just check`.

Don't hand-write what the script generates. If the script fails, show the error and fix the cause. Don't continue from a half-made project; delete it and rerun.

## What the agent template gives you (`--agent`)
- `agent/tools.py`: `ToolRegistry`. Each tool is a function with a Pydantic input model. Bad input and `ToolError` come back to the model as `is_error` results instead of raising.
- `agent/app_tools.py`: the app's tools. Replace the example `add` tool.
- `agent/loop.py`: `run_agent(task, model=..., registry=...)` returns the final text plus every tool step (an audit trail). `AnthropicModel` is the real client.
- `tests/fakes.py`: `ScriptedModel`, `tool_call()`, `text()` for deterministic tests with no network.
- `just agent "<task>"` runs it live (needs `ANTHROPIC_API_KEY`, e.g. in `.envrc`).
