#!/usr/bin/env bash
# Set up a new machine from ~/projects/dotfiles. Safe to rerun.
set -euo pipefail
DOT="$HOME/projects/dotfiles"

# Link a dotfile into $HOME, backing up any real file that's already there.
link() {
  local src="$DOT/$1" dst="$HOME/$1"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
    echo "    backed up existing $dst"
  fi
  ln -sfn "$src" "$dst"
}

echo "==> Dotfiles"
link .zshrc
link .vimrc
link .gitconfig
# Clean up the dangling link older versions of this script created.
[ -L "$HOME/.zsh" ] && [ ! -e "$HOME/.zsh" ] && rm "$HOME/.zsh"

echo "==> Shell"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
brew install --quiet figlet fortune cowsay lolcat

echo "==> Node"
# Keep an existing Node (nvm, fnm, Volta, brew...); install one only if missing.
if command -v node >/dev/null; then
  echo "    using existing node $(node --version)"
else
  brew install --quiet node
fi

# Claude Code config: links CLAUDE.md, hooks, skills, agents (safe to rerun on its own)
"$DOT/claude/install.sh"

# iTerm2 profile + background image (safe to rerun), set as the default profile.
echo "==> iTerm2"
mkdir -p ~/Library/Application\ Support/iTerm2/DynamicProfiles
sed "s|__DOTFILES__|$DOT|" "$DOT/iterm/profile.json" > ~/Library/Application\ Support/iTerm2/DynamicProfiles/dotfiles.json
ITERM_GUID="AF01C719-D470-4A7B-A616-931EE81F45DF"
set_iterm_default='defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string '"$ITERM_GUID"
iterm_running() { ps -Ao comm= | grep '/iTerm.app/Contents/MacOS/iTerm2$' >/dev/null; }
eval "$set_iterm_default"
if iterm_running; then
  # A running iTerm keeps its own default and writes it back on quit, so set
  # ours again once it has exited. Takes effect the next time iTerm opens.
  waiter="while ps -Ao comm= | grep '/iTerm.app/Contents/MacOS/iTerm2\$' >/dev/null; do sleep 2; done; $set_iterm_default"
  if ! ps -Ao command= | grep -x -F "bash -c $waiter" >/dev/null; then  # one is enough
    nohup bash -c "$waiter" >/dev/null 2>&1 &
    disown
  fi
  echo "    iTerm is open: quit it (Cmd+Q) and reopen to switch to the Dotfiles profile."
fi

echo "==> All set. Open a new terminal to load the shell config."
