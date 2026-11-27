
ln -s ~/projects/dotfiles/.vimrc ~/.vimrc 
ln -s ~/projects/dotfiles/.gitconfig ~/.gitconfig
ln -s ~/projects/dotfiles/.zsh ~/.zsh

brew install zsh figlet fortune cowthink lolcat



# AI dev kit: toolchain + Claude Code config (safe to rerun on its own)
~/projects/dotfiles/claude/install.sh
