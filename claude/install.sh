#!/usr/bin/env bash
# Install the AI dev kit: toolchain + Claude Code config. Safe to rerun.
set -euo pipefail
DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
C="$HOME/.claude"

echo "==> Toolchain"
brew bundle --quiet --file "$DOT/Brewfile"
uv python install 3.12 >/dev/null
for t in ruff pyright pytest; do uv tool install -q "$t" 2>/dev/null || true; done

echo "==> Claude Code config"
mkdir -p "$C/hooks" "$C/skills"
ln -sfn "$DOT/claude/CLAUDE.md" "$C/CLAUDE.md"
ln -sfn "$DOT/claude/hooks/lint-on-edit.sh" "$C/hooks/lint-on-edit.sh"
ln -sfn "$DOT/claude/skills/scaffold-app" "$C/skills/scaffold-app"

# settings.json is merged, not symlinked: Claude Code writes to it.
S="$C/settings.json"
[ -f "$S" ] || echo '{}' > "$S"
cp "$S" "$S.bak"
jq -s '
  .[0] as $cur | .[1] as $add
  | def merge(k): (($cur.permissions[k] // []) + ($add.permissions[k] // [])) | unique;
    def addhooks(ev): ($cur.hooks[ev] // []) as $old
      | $old + [ $add.hooks[ev][] | select(. as $h | $old | index([$h]) | not) ];
  $cur
  | .permissions.allow = merge("allow")
  | .permissions.ask = merge("ask")
  | .permissions.deny = merge("deny")
  | .hooks.PostToolUse = addhooks("PostToolUse")
' "$S.bak" "$DOT/claude/settings.add.json" > "$S"

echo "==> Done. Previous settings saved to $S.bak"
