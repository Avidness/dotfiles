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

# Claude Code config: links CLAUDE.md, hooks, skills, agents (safe to rerun on its own)
"$DOT/claude/install.sh"

# iTerm2 profile + background image (safe to rerun). Run before first launching iTerm,
# or pick "Dotfiles" under Settings > Profiles > Other Actions > Set as Default.
echo "==> iTerm2"
mkdir -p ~/Library/Application\ Support/iTerm2/DynamicProfiles
sed "s|__DOTFILES__|$DOT|" "$DOT/iterm/profile.json" > ~/Library/Application\ Support/iTerm2/DynamicProfiles/dotfiles.json
defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "AF01C719-D470-4A7B-A616-931EE81F45DF"

echo "==> All set. Open a new terminal to load the shell config."
