
ln -s ~/projects/dotfiles/.vimrc ~/.vimrc 
ln -s ~/projects/dotfiles/.gitconfig ~/.gitconfig
ln -s ~/projects/dotfiles/.zsh ~/.zsh

brew install zsh figlet fortune cowthink lolcat



# AI dev kit: toolchain + Claude Code config (safe to rerun on its own)
~/projects/dotfiles/claude/install.sh

# iTerm2 profile + background image (safe to rerun). Run before first launching iTerm,
# or pick "Dotfiles" under Settings > Profiles > Other Actions > Set as Default.
mkdir -p ~/Library/Application\ Support/iTerm2/DynamicProfiles
sed "s|__DOTFILES__|$HOME/projects/dotfiles|" ~/projects/dotfiles/iterm/profile.json > ~/Library/Application\ Support/iTerm2/DynamicProfiles/dotfiles.json
defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "AF01C719-D470-4A7B-A616-931EE81F45DF"
