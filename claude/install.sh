#!/usr/bin/env bash
# Install the AI dev kit: toolchain + Claude Code config. Safe to rerun.
set -euo pipefail
DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
C="$HOME/.claude"

echo "==> Toolchain"
# --no-upgrade: install what's missing, never upgrade apps (casks like Docker need sudo).
brew bundle --quiet --no-upgrade --file "$DOT/Brewfile" \
  || echo "warning: some Brewfile entries failed; continuing" >&2
uv python install 3.12 >/dev/null
for t in ruff pyright pytest; do uv tool install -q "$t" 2>/dev/null || true; done

echo "==> Claude Code config"
mkdir -p "$C/hooks" "$C/skills" "$C/agents"
ln -sfn "$DOT/claude/CLAUDE.md" "$C/CLAUDE.md"
ln -sfn "$DOT/claude/hooks/lint-on-edit.sh" "$C/hooks/lint-on-edit.sh"
for skill in "$DOT"/claude/skills/*/; do
  ln -sfn "${skill%/}" "$C/skills/$(basename "$skill")"
done
# Drop links to agents that were removed from dotfiles, then link the current ones.
find "$C/agents" -maxdepth 1 -type l ! -exec test -e {} \; -delete
for agent in "$DOT"/claude/agents/*.md; do
  ln -sfn "$agent" "$C/agents/$(basename "$agent")"
done

echo "==> Playwright (browser for e2e tests + MCP server for Claude)"
npx -y playwright@1.56.1 install chromium >/dev/null
if ! claude mcp get playwright >/dev/null 2>&1; then
  claude mcp add --scope user playwright -- npx @playwright/mcp@latest
fi

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
