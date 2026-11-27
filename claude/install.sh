#!/usr/bin/env bash
# Link the Claude Code config (CLAUDE.md, hooks, skills, agents) into ~/.claude
# and merge settings. Installs no software. Safe to rerun.
set -euo pipefail
DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
C="$HOME/.claude"

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
