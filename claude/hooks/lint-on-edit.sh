#!/usr/bin/env bash
# PostToolUse hook: format + lint the file Claude just edited.
# Runs only in projects that opted in (ruff config / biome.json), so older
# projects don't get reformatted. Exit 2 sends the errors back to Claude.

f=$(jq -r '.tool_input.file_path // empty')
[ -f "$f" ] || exit 0

# Nearest ancestor directory of the file containing one of the given names.
find_up() {
  local d
  d=$(dirname "$1"); shift
  while [ "$d" != "/" ]; do
    for n in "$@"; do [ -e "$d/$n" ] && { echo "$d"; return 0; }; done
    d=$(dirname "$d")
  done
  return 1
}

# Nearest directory with ruff.toml, .ruff.toml, or a pyproject.toml that has [tool.ruff].
ruff_root() {
  local d
  d=$(dirname "$1")
  while [ "$d" != "/" ]; do
    [ -e "$d/ruff.toml" ] || [ -e "$d/.ruff.toml" ] && { echo "$d"; return 0; }
    grep -qs '^\[tool\.ruff' "$d/pyproject.toml" && { echo "$d"; return 0; }
    d=$(dirname "$d")
  done
  return 1
}

case "$f" in
  *.py)
    root=$(ruff_root "$f") || exit 0
    cd "$root" || exit 0
    ruff format -q "$f"
    out=$(ruff check --fix -q "$f" 2>&1) ;;
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css)
    root=$(find_up "$f" biome.json biome.jsonc) || exit 0
    cd "$root" || exit 0
    out=$(biome check --write --no-errors-on-unmatched "$f" 2>&1) ;;
  *) exit 0 ;;
esac

[ $? -eq 0 ] && exit 0
echo "Lint errors in $f (fix these):" >&2
echo "$out" >&2
exit 2
