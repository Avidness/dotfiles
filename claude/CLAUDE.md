# Defaults (all projects)

## Stack
- Python 3.12 via uv (`uv add`, `uv run`). Never pip or conda for new work.
- Python lint/format: ruff. Types: pyright. Tests: pytest.
- TypeScript via pnpm. Lint/format: biome. Tests: vitest.
- Services (Postgres, Redis) via docker compose.
- LLM features: the Anthropic SDK, model `claude-opus-5-5` unless told otherwise.
- New apps: use the scaffold-app skill instead of setting up by hand.

## Working rules
- Every project has a justfile. Use `just <task>`, not raw commands.
- Write or update a failing test before the implementation.
- A task is done only when `just check` passes. Show the output.
- Small, focused changes. Don't refactor unrelated code.
- No new dependency without one sentence on why.
- Never read or edit .env files; use .env.example.
- Tests never call real LLM APIs; use a scripted fake model.
- If stuck after two attempts, stop and explain what you tried.
