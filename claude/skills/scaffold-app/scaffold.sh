#!/usr/bin/env bash
# Create a new app with lint, types, tests, git hooks and CI working from commit one.
# usage: scaffold.sh <name> [--agent] [--web] [--postgres] [--dir <parent>]
set -euo pipefail

usage() { echo "usage: scaffold.sh <name> [--agent] [--web] [--postgres] [--dir <parent>]" >&2; exit 1; }
[ $# -ge 1 ] || usage
NAME=$1; shift
AGENT=0; WEB=0; PG=0; PARENT="$HOME/projects"
while [ $# -gt 0 ]; do
  case $1 in
    --agent) AGENT=1 ;;
    --web) WEB=1 ;;
    --postgres) PG=1 ;;
    --dir) PARENT=$2; shift ;;
    *) usage ;;
  esac
  shift
done

PKG=$(echo "$NAME" | tr '[:upper:]-' '[:lower:]_')
T="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/templates"
ROOT="$PARENT/$NAME"
[ -e "$ROOT" ] && { echo "error: $ROOT already exists" >&2; exit 1; }

step() { printf '\n==> %s\n' "$1"; }
render() { mkdir -p "$(dirname "$2")"; sed -e "s/__NAME__/$NAME/g" -e "s/__PKG__/$PKG/g" "$1" > "$2"; }

mkdir -p "$ROOT"
cd "$ROOT"
git init -q

# ---------------------------------------------------------------- api
step "API: FastAPI + uv + pytest + ruff + pyright"
uv init -q --package --name "$PKG" --python 3.12 --no-readme --vcs none api
cd api
uv add -q fastapi 'uvicorn[standard]'
uv add -q --dev pytest httpx2 ruff pyright
cat "$T/api/pyproject.tool.toml" >> pyproject.toml
render "$T/api/main.py" "src/$PKG/main.py"
mkdir -p tests && touch tests/__init__.py
render "$T/api/test_health.py" tests/test_health.py

if [ $AGENT = 1 ]; then
  step "Agent: Claude tool-use loop + scripted fake model"
  uv add -q anthropic
  mkdir -p "src/$PKG/agent" && touch "src/$PKG/agent/__init__.py"
  for f in tools.py app_tools.py loop.py __main__.py; do render "$T/agent/$f" "src/$PKG/agent/$f"; done
  render "$T/agent/fakes.py" tests/fakes.py
  render "$T/agent/test_agent.py" tests/test_agent.py
fi
[ $PG = 1 ] && uv add -q 'psycopg[binary]'
uv run -q ruff format -q . && uv run -q ruff check -q --fix .
cd ..

# ---------------------------------------------------------------- web
if [ $WEB = 1 ]; then
  step "Web: Vite + React + TypeScript + biome + vitest"
  pnpm dlx create-vite@6 web --template react-ts >/dev/null
  cd web
  rm -f eslint.config.js
  printf 'allowBuilds:\n  esbuild: true\n' > pnpm-workspace.yaml  # pnpm 11+ blocks build scripts by default
  pnpm install --silent
  pnpm remove --silent eslint @eslint/js eslint-plugin-react-hooks eslint-plugin-react-refresh globals typescript-eslint 2>/dev/null || true
  pnpm add -D --silent @biomejs/biome vitest
  render "$T/web/vite.config.ts" vite.config.ts
  render "$T/web/App.tsx" src/App.tsx
  render "$T/web/main.tsx" src/main.tsx
  rm -rf src/App.css src/assets public/vite.svg
  : > src/index.css
  npm pkg set scripts.lint="biome check ." scripts.test="vitest run" >/dev/null
  pnpm exec biome init >/dev/null
  pnpm exec biome check --write . >/dev/null || true
  cd ..
fi

# ---------------------------------------------------------------- services
if [ $PG = 1 ]; then
  cat > docker-compose.yml <<EOF
services:
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app
      POSTGRES_DB: $PKG
    ports: ["5432:5432"]
    volumes: [db-data:/var/lib/postgresql/data]
volumes:
  db-data:
EOF
fi

# ---------------------------------------------------------------- env
{
  [ $PG = 1 ] && echo "DATABASE_URL=postgresql://app:app@localhost:5432/$PKG"
  [ $AGENT = 1 ] && echo "ANTHROPIC_API_KEY="
  true
} > .env.example
cat > .gitignore <<'EOF'
.env
.envrc
.venv/
__pycache__/
.pytest_cache/
.ruff_cache/
node_modules/
dist/
.DS_Store
EOF

# ---------------------------------------------------------------- justfile
w() { printf '%s\n' "$@" >> justfile; }
: > justfile
w "set dotenv-load" "" "default:" "    @just --list" ""
w "# Run the app for development" "dev:" "    #!/usr/bin/env bash" "    set -e"
[ $PG = 1 ] && w "    docker compose up -d"
[ $WEB = 1 ] && w "    trap 'kill 0' EXIT" "    (cd web && pnpm dev) &"
w "    cd api && uv run uvicorn $PKG.main:app --reload" ""
w "# Lint, types and tests: must pass before a task is done" "check: lint types test" ""
w "lint:" "    cd api && uv run ruff check . && uv run ruff format --check ."
[ $WEB = 1 ] && w "    cd web && pnpm exec biome check ."
w "" "# Auto-fix lint and formatting" "fix:" "    cd api && uv run ruff check --fix . && uv run ruff format ."
[ $WEB = 1 ] && w "    cd web && pnpm exec biome check --write ."
w "" "types:" "    cd api && uv run pyright"
[ $WEB = 1 ] && w "    cd web && pnpm exec tsc -b"
w "" "test *ARGS:" "    cd api && uv run pytest -q {{ARGS}}"
[ $WEB = 1 ] && w "    cd web && pnpm exec vitest run"
if [ $AGENT = 1 ]; then
  w "" "# Run the agent live against Claude" "agent *TASK:" "    cd api && uv run python -m $PKG.agent \"{{TASK}}\""
fi

# ---------------------------------------------------------------- CLAUDE.md
{
  echo "# $NAME"
  echo
  echo "## Commands"
  echo "- \`just dev\`: run the app (API on :8000$([ $WEB = 1 ] && echo ', web on :5173'))"
  echo "- \`just check\`: lint + types + tests. Must pass before a task is done."
  echo "- \`just fix\`: auto-fix lint and formatting"
  echo "- \`just test -k <name>\`: run matching Python tests"
  [ $AGENT = 1 ] && echo "- \`just agent \"<task>\"\`: run the agent live (needs ANTHROPIC_API_KEY in .envrc)"
  echo
  echo "## Layout"
  echo "- \`api/src/$PKG/main.py\`: FastAPI app. Routes live under \`/api\`."
  echo "- \`api/tests/\`: pytest"
  if [ $AGENT = 1 ]; then
    echo "- \`api/src/$PKG/agent/app_tools.py\`: the agent's tools (Pydantic input model per tool)"
    echo "- \`api/src/$PKG/agent/loop.py\`: \`run_agent()\` loop and \`AnthropicModel\`"
    echo "- \`api/tests/fakes.py\`: \`ScriptedModel\` for agent tests. Tests never call the real API."
  fi
  [ $WEB = 1 ] && echo "- \`web/\`: Vite + React + TS. Dev server proxies \`/api\` to :8000."
  [ $PG = 1 ] && echo "- \`docker-compose.yml\`: Postgres. \`DATABASE_URL\` in .env (see .env.example)."
  echo
  echo "## Rules"
  echo "- (Domain rules go here: states, invariants, limits, what needs human approval.)"
} > CLAUDE.md

# ---------------------------------------------------------------- CI
mkdir -p .github/workflows
{
  cat <<'EOF'
name: ci
on: [push, pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v6
      - uses: extractions/setup-just@v3
EOF
  if [ $WEB = 1 ]; then
    cat <<'EOF'
      - uses: pnpm/action-setup@v4
        with: { package_json_file: web/package.json }
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: pnpm, cache-dependency-path: web/pnpm-lock.yaml }
      - run: cd web && pnpm install --frozen-lockfile
EOF
  fi
  echo "      - run: just check"
} > .github/workflows/ci.yml
if [ $WEB = 1 ]; then (cd web && npm pkg set packageManager="pnpm@$(pnpm --version)" >/dev/null); fi

cp "$T/lefthook.yml" lefthook.yml

# ---------------------------------------------------------------- verify + commit
step "Running just check"
just check

git add -A
git commit -q -m "Scaffold $NAME"
lefthook install >/dev/null

step "Done: $ROOT"
echo "  just dev     run the app"
echo "  just check   lint + types + tests"
[ $AGENT = 1 ] && echo "  just agent \"<task>\"   run the agent live"
exit 0
